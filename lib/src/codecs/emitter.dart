import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'cacher.dart';
import '../constants.dart';
import '../handlers/write_handlers.dart';

abstract class Emitter {
  final WriteHandlers _writeHandlers;
  late final CacheEncoder _cache;
  final bool _verbose;
  late final WriteHandler? _defaultHandler;

  Emitter(this._writeHandlers,
      {CacheEncoder? cache,
      bool verbose = false,
      WriteHandler<dynamic, dynamic>? defaultHandler})
      : _defaultHandler = defaultHandler,
        _verbose = verbose {
    _cache = cache ?? CacheEncoder();
  }

  dynamic emit(dynamic obj) {
    _cache.init();
    return marshalTop(obj);
  }

  dynamic marshalTop(dynamic obj) {
    // If single item, wrap it as a quoted value. NOTE: not necessary for
    // msgpack, but afaict java and clj implementations do it anyway.
    var h = _writeHandlers.getHandler(obj) ?? _defaultHandler;
    if (null == h) {
      throw Exception('Not supported: $obj');
    }
    var tag = h.tag(obj);
    if (1 == tag.length) {
      var tag = '$ESC_TAG$QUOTE';
      if (_verbose) {
        return {tag: marshal(obj)};
      } else {
        return [tag, marshal(obj)];
      }
    }
    return marshal(obj);
  }

  dynamic marshal(dynamic obj, {bool asMapKey = false}) {
    // Emit ground types here, otherwise emit as tagged value.
    var handler = _writeHandlers.getHandler(obj) ?? _defaultHandler;
    if (null == handler) {
      throw Exception('Not supported: $obj');
    }
    var tag = handler.tag(obj);
    switch (tag) {
      case '_':
        return emitNull(asMapKey);
      case 's':
        return emitString(null, null, escape(handler.rep(obj)), asMapKey);
      case '?':
        return emitBoolean(handler.rep(obj), asMapKey);
      case 'i':
        return emitInteger(handler.rep(obj), asMapKey);
      case 'd':
        return emitDouble(handler.rep(obj), asMapKey);
      case 'b':
        return emitBinary(handler.rep(obj), asMapKey);
      case 'array':
        return emitArray(handler.rep(obj), asMapKey);
      case 'map':
        return emitMap(handler.rep(obj, tag: tag), asMapKey);
      default:
        return emitEncoded(handler, obj, asMapKey);
    }
  }

  dynamic emitNull(bool asMapKey);

  String emitString(String? prefix, String? tag, String s, bool asMapKey) {
    s = '${prefix ?? ''}${tag ?? ''}$s';
    s = _cache.convert(s, asMapKey: asMapKey);
    return s;
  }

  dynamic emitBoolean(bool b, bool asMapKey);
  dynamic emitInteger(int i, bool asMapKey);
  dynamic emitDouble(double d, bool asMapKey);
  dynamic emitBinary(Uint8List b, bool asMapKey);
  dynamic emitMap(Map m, bool asMapKey);

  List emitArray(List l, bool asMapKey) {
    return [...l.map((e) => marshal(e))];
  }

  dynamic emitEncoded(WriteHandler handler, dynamic obj, bool asMapKey) {
    if (_verbose) {
      handler = handler.verboseHandler(obj) ?? handler;
    }
    var rep = handler.rep(obj);
    var tag = handler.tag(obj);
    if (1 == tag.length) {
      if (rep is String) {
        return emitString(ESC, tag, rep, asMapKey);
      } else if (prefersStrings || asMapKey) {
        String? sr = handler.stringRep(obj);
        if (null != sr) {
          return emitString(ESC, tag, sr, asMapKey);
        } else {
          throw Exception('Cannot be encoded as a string $obj');
        }
      } else {
        return emitTagged(tag, rep, asMapKey);
      }
    } else if (asMapKey) {
      throw Exception('Cannot be used as map key $obj');
    } else {
      return emitTagged(tag, rep, asMapKey);
    }
  }

  List emitTagged(String tag, dynamic obj, bool asMapKey) {
    return [emitString(ESC_TAG, tag, '', false), marshal(obj)];
  }

  String escape(String s) {
    if (s.isNotEmpty) {
      if (s.startsWith(ESC) || s.startsWith(SUB) || s.startsWith(RESERVED)) {
        return '$ESC$s';
      }
    }
    return s;
  }

  bool get prefersStrings;
}

class JsonEmitter extends Emitter {
  // concrete implementations for emitting strings, booleans, decimals, etc.
  // What we actually emit is formatted data, json-friendly.

  JsonEmitter(super.writeHandlers,
      {super.cache, super.defaultHandler, super.verbose});

  @override
  bool get prefersStrings => true;

  @override
  emitNull(bool asMapKey) {
    if (asMapKey) {
      return emitString(ESC, '_', '', asMapKey);
    } else {
      return null;
    }
  }

  @override
  emitBoolean(bool b, bool asMapKey) {
    if (asMapKey) {
      return emitString(ESC, '?', b ? 't' : 'f', asMapKey);
    } else {
      return b;
    }
  }

  @override
  emitInteger(int i, bool asMapKey) {
    if (asMapKey || i != i.toSigned(53)) {
      return emitString(ESC, 'i', i.toString(), asMapKey);
    } else {
      return i;
    }
  }

  @override
  emitDouble(double d, bool asMapKey) {
    if (asMapKey) {
      return emitString(ESC, 'd', d.toString(), asMapKey);
    } else {
      return d;
    }
  }

  @override
  emitBinary(Uint8List b, bool asMapKey) {
    return emitString(ESC, 'b', base64.encode(b), asMapKey);
  }

  @override
  emitMap(Map m, bool asMapKey) {
    return [
      MAP,
      ...m.entries
          .expand((e) => [marshal(e.key, asMapKey: true), marshal(e.value)])
    ];
  }
}

class MessagePackEmitter extends Emitter {
  MessagePackEmitter(super.writeHandlers, {super.cache, super.defaultHandler});

  @override
  bool get prefersStrings => false;

  @override
  emitNull(bool asMapKey) => null;

  @override
  emitBoolean(bool b, bool asMapKey) => b;

  @override
  emitInteger(int i, bool asMapKey) => i;

  @override
  emitDouble(double d, bool asMapKey) => d;

  @override
  emitBinary(Uint8List b, bool asMapKey) => b;

  // Use a [LinkedHashMap] to preserve key-value pair order.
  @override
  emitMap(Map m, bool asMapKey) {
    var sorted = LinkedHashMap(); // ignore: prefer_collection_literals
    for (var e in m.entries) {
      var key = marshal(e.key, asMapKey: true);
      var val = marshal(e.value, asMapKey: false);
      sorted[key] = val;
    }
    return sorted;
  }
}

// abstract class DefaultWriteHandler<T> {
//   T fromRep(String tag, dynamic rep);
// }
