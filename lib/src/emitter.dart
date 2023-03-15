import 'dart:convert';
import 'dart:typed_data';

import 'cacher.dart';
import 'constants.dart';
import 'handlers/write_handlers.dart';

abstract class Emitter {
  final WriteHandlersMap writeHandlersMap;
  final CacheEncoder cache;
  WriteHandler? defaultHandler;

  Emitter(this.writeHandlersMap, this.cache);

  marshalTop(obj) {
    cache.init();
    var h = writeHandlersMap.getHandler(obj) ?? defaultHandler;
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
    var h = writeHandlersMap.getHandler(obj) ?? defaultHandler;
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
        return emitMap(h.rep(obj), asMapKey);
      } else {
        return emitEncoded(tag, h, obj, asMapKey);
      }
    }
  }

  // If we turn this into a coder/codec then this `emit` method will become the
  // `convert` method.
  emit(obj, {bool asMapKey = false}) => marshalTop(obj);

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
        emitTagged(t, r, asMapKey);
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

  JsonEmitter(super.writeHandlersMap, super.cache);

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
    s = cache.convert(s, asMapKey: asMapKey);
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
