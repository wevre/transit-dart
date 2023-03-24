import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'cacher.dart';
import 'constants.dart';
import 'handlers/write_handlers.dart';

abstract class Emitter {
  final WriteHandlers _writeHandlers;
  late final CacheEncoder _cache;
  late final WriteHandler? _defaultHandler;

  Emitter(this._writeHandlers,
      {CacheEncoder? cache, WriteHandler<dynamic, dynamic>? defaultHandler})
      : _defaultHandler = defaultHandler {
    _cache = cache ?? CacheEncoder();
  }

  marshalTop(obj) {
    _cache.init();
    var h = _writeHandlers.getHandler(obj) ?? _defaultHandler;
    if (null == h) {
      throw Exception('Not supported: $obj');
    }
    var tag = h.tag(obj);
    if (1 == tag.length) {
      return emitTagged(QUOTE, obj, false);
    }
    return marshal(obj);
  }

  marshal(obj, {bool asMapKey = false}) {
    var h = _writeHandlers.getHandler(obj) ?? _defaultHandler;
    if (null == h) {
      throw Exception('Not supported: $obj');
    }
    var tag = h.tag(obj);
    if (1 == tag.length) {
      switch (tag) {
        case '_':
          return emitNull(asMapKey);
        case 's':
          return emitString(null, null, escape(h.rep(obj)), asMapKey);
        case '?':
          return emitBoolean(h.rep(obj), asMapKey);
        case 'i':
          return emitInteger(h.rep(obj), asMapKey);
        case 'd':
          return emitDouble(h.rep(obj), asMapKey);
        case 'b':
          return emitBinary(h.rep(obj), asMapKey);
        default:
          return emitEncoded(tag, h, obj, asMapKey);
      }
    } else {
      if ('array' == tag) {
        return emitArray(h.rep(obj), asMapKey);
      } else if ('map' == tag) {
        return emitMap(h.rep(obj, tag: tag), asMapKey);
      } else {
        return emitEncoded(tag, h, obj, asMapKey);
      }
    }
  }

  emit(obj) => marshalTop(obj);

  emitNull(bool asMapKey);
  emitString(String? prefix, String? tag, String s, bool asMapKey);
  emitBoolean(bool b, bool asMapKey);
  emitInteger(int i, bool asMapKey);
  emitDouble(double d, bool asMapKey);
  emitBinary(Uint8List b, bool asMapKey);
  emitMap(Map m, bool asMapKey);

  emitArray(List l, bool asMapKey) {
    return [...l.map((e) => marshal(e))];
  }

  emitEncoded(String t, WriteHandler h, o, bool asMapKey) {
    if (1 == t.length) {
      var r = h.rep(o);
      if (r is String) {
        return emitString(ESC, t, r, asMapKey);
      } else if (prefersStrings() || asMapKey) {
        String? sr = h.stringRep(o);
        if (null != sr) {
          return emitString(ESC, t, sr, asMapKey);
        } else {
          throw Exception('Cannot be encoded as a string $o');
        }
      } else {
        return emitTagged(t, r, asMapKey);
      }
    } else if (asMapKey) {
      throw Exception('Cannot be used as map key $o');
    } else {
      return emitTagged(t, h.rep(o), asMapKey);
    }
  }

  emitTagged(String t, o, bool asMapKey) {
    return [emitString(ESC_TAG, t, '', false), marshal(o)];
  }

  String escape(String s) {
    if (s.isNotEmpty) {
      if (s.startsWith(ESC) || s.startsWith(SUB) || s.startsWith(RESERVED)) {
        return '$ESC$s';
      }
    }
    return s;
  }

  bool prefersStrings();
}

class JsonEmitter extends Emitter {
  // concrete implementations for emitting strings, booleans, decimals, etc.
  // What we actually emit is formatted data, json-friendly.

  JsonEmitter(super.writeHandlers, {super.cache, super.defaultHandler});

  @override
  prefersStrings() => true;

  @override
  emitNull(bool asMapKey) {
    if (asMapKey) {
      return emitString(ESC, '_', '', asMapKey);
    } else {
      return null;
    }
  }

  @override
  emitString(String? prefix, String? tag, String s, bool asMapKey) {
    s = '${prefix ?? ''}${tag ?? ''}$s';
    s = _cache.convert(s, asMapKey: asMapKey);
    return s;
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
  bool prefersStrings() => false;

  @override
  emitNull(bool asMapKey) => null;

  @override
  emitString(String? prefix, String? tag, String s, bool asMapKey) {
    s = '${prefix ?? ''}${tag ?? ''}$s';
    s = _cache.convert(s, asMapKey: asMapKey);
    return s;
  }

  @override
  emitBoolean(bool b, bool asMapKey) => b;

  @override
  emitInteger(int i, bool asMapKey) => i;

  @override
  emitDouble(double d, bool asMapKey) => d;

  @override
  emitBinary(Uint8List b, bool asMapKey) => b;

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
