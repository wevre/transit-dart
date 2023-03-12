import 'dart:convert';
import 'dart:typed_data';

import 'cache.dart';
import 'write_handler.dart';

abstract class Emitter {
  WriteHandlersMap writeHandlerMap;
  CacheEncoder cache;

  Emitter(this.writeHandlerMap, this.cache);

  marshalTop(o) {
    var h = writeHandlerMap.getHandler(o);
    h ??= DefaultWriteHandler();
    var tag = h.tag(o);
    if (1 == tag.length) {
      return emitTagged("'", o, false);
    }
    return marshal(o, false);
  }

  marshal(o, bool asMapKey) {
    var h = writeHandlerMap.getHandler(o);
    h ??= DefaultWriteHandler();
    var tag = h.tag(o);
    if (1 == tag.length) {
      switch (tag) {
        case '_':
          return emitNull(asMapKey);
        case 's':
          return emitString(null, null, escape(h.rep(o)), asMapKey);
        case '?':
          return emitBoolean(h.rep(o), asMapKey);
        case 'i':
          return emitInteger(h.rep(o), asMapKey);
        case 'd':
          return emitDouble(h.rep(o), asMapKey);
        case 'b':
          return emitBinary(h.rep(o), asMapKey);
        default:
          return emitEncoded(tag, h, o, asMapKey);
      }
    } else {
      if ('array' == tag) {
        return emitArray(h.rep(o), asMapKey);
      } else if ('map' == tag) {
        return emitMap(h.rep(o), asMapKey);
      } else {
        return emitEncoded(tag, h, o, asMapKey);
      }
    }
  }

  // If we turn this into a coder/codec then this `emit` method will become the
  // `convert` method.
  emit(o, bool asMapKey) => marshalTop(o);

  emitNull(bool asMapKey);
  emitString(String? prefix, String? tag, String s, bool asMapKey);
  emitBoolean(bool b, bool asMapKey);
  emitInteger(int i, bool asMapKey);
  emitDouble(double d, bool asMapKey);
  emitBinary(Uint8List b, bool asMapKey);
  emitMap(Map m, bool asMapKey);

  emitArray(List l, bool asMapKey) {
    return [...l.map((e) => marshal(e, false))];
  }

  emitEncoded(String t, WriteHandler h, o, bool asMapKey) {
    if (1 == t.length) {
      var r = h.rep(o);
      if (r is String) {
        return emitString('~', t, r, asMapKey);
      } else if (prefersStrings() || asMapKey) {
        String? sr = h.stringRep(o);
        if (sr != null) {
          return emitString('~', t, sr, asMapKey);
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
    return [emitString('~#', t, '', false), marshal(o, false)];
  }

  String escape(String s) {
    if (s.isNotEmpty) {
      if (s.startsWith('~') || s.startsWith('^') || s.startsWith('``')) {
        return '~$s';
      }
    }
    return s;
  }

  bool prefersStrings();
}

class JsonEmitter extends Emitter {
  // concrete implementations for emitting strings, booleans, decimals, etc.
  // What we actually emit is formatted data, json-friendly.

  JsonEmitter(super.writeHandlerMap, super.cache);

  @override
  prefersStrings() => true;

  @override
  emitNull(bool asMapKey) {
    if (asMapKey) {
      return emitString('~', '_', '', asMapKey);
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
      return emitString('~', '?', b ? 't' : 'f', asMapKey);
    } else {
      return b;
    }
  }

  @override
  emitInteger(int i, bool asMapKey) {
    if (asMapKey || i != i.toSigned(53)) {
      return emitString('~', 'i', i.toString(), asMapKey);
    } else {
      return i;
    }
  }

  @override
  emitDouble(double d, bool asMapKey) {
    if (asMapKey) {
      return emitString('~', 'd', d.toString(), asMapKey);
    } else {
      return d;
    }
  }

  @override
  emitBinary(Uint8List b, bool asMapKey) {
    return emitString('~', 'b', base64.encode(b), asMapKey);
  }

  @override
  emitMap(Map m, bool asMapKey) {
    return [
      '^ ',
      ...m.entries
          .expand((e) => [marshal(e.key, true), marshal(e.value, false)])
    ];
  }
}
