import 'package:collection/collection.dart';

import 'cacher.dart';
import '../constants.dart';
import '../handlers/array_builder.dart';
import '../handlers/map_builder.dart';
import '../handlers/read_handlers.dart';
import '../values/tag.dart';
import '../values/tagged_value.dart';

class Parser {
  final ReadHandlers _readHandlers;
  late final CacheDecoder _cache;
  late final DefaultReadHandler _defaultHandler;
  late final MapBuilder _mapBuilder;
  late final ArrayBuilder _arrayBuilder;

  Parser(this._readHandlers,
      {CacheDecoder? cache,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder}) {
    _cache = cache ?? CacheDecoder();
    _defaultHandler = defaultHandler ?? TaggedValueReadHandler();
    _mapBuilder = mapBuilder ?? MapBuilderImpl();
    _arrayBuilder = arrayBuilder ?? ArrayBuilderImpl();
  }

  dynamic parse(dynamic obj) {
    _cache.init();
    return parseVal(obj);
  }

  dynamic parseVal(dynamic obj, {bool asMapKey = false}) {
    if (obj is Map) {
      return parseMap(obj, asMapKey, null);
    } else if (obj is List) {
      return parseArray(obj, asMapKey, null);
    } else if (obj is String) {
      return _cache.convert(obj,
          asMapKey: asMapKey, parseFn: (obj) => parseString(obj));
    } else {
      return obj;
    }
  }

  dynamic parseTag(String tag, dynamic obj, bool asMapKey) {
    ReadHandler? valHandler = _readHandlers.getHandler(tag);
    dynamic val;
    if (null != valHandler) {
      if (obj is Map && valHandler is MapReadHandler) {
        val = parseMap(obj, asMapKey, valHandler);
      } else if (obj is List && valHandler is ArrayReadHandler) {
        val = parseArray(obj, asMapKey, valHandler);
      } else {
        val = valHandler.fromRep(parseVal(obj, asMapKey: asMapKey));
      }
    } else {
      val = decode(tag, parseVal(obj, asMapKey: asMapKey));
    }
    return val;
  }

  dynamic parseMap(Map obj, bool asMapKey, MapReadHandler? handler) {
    MapBuilder mb = handler?.mapBuilder() ?? _mapBuilder;
    var mr = mb.init();
    for (var e in obj.entries) {
      var key = parseVal(e.key, asMapKey: true);
      if (key is Tag) {
        return parseTag(key.value, e.value, asMapKey);
      } else {
        mr = mb.add(mr, key, parseVal(e.value));
      }
    }
    return mb.complete(mr);
  }

  dynamic parseEntries(
      List<MapEntry> objs, bool asMapKey, MapReadHandler? handler) {
    MapBuilder mb = handler?.mapBuilder() ?? _mapBuilder;
    var mr = mb.init();
    for (var e in objs) {
      mr = mb.add(mr, parseVal(e.key, asMapKey: true),
          parseVal(e.value, asMapKey: false));
    }
    return mb.complete(mr);
  }

  dynamic parseArray(List obj, bool asMapKey, ArrayReadHandler? handler) {
    if (obj.isEmpty) {
      // Make an empty list with the default ArrayBuilder
      ArrayBuilder ab = handler?.arrayBuilder() ?? _arrayBuilder;
      return ab.complete(ab.init());
    }
    var firstVal = parseVal(obj[0], asMapKey: asMapKey);
    if (MAP == firstVal) {
      return parseEntries(
          [...obj.sublist(1).slices(2).map((e) => MapEntry(e[0], e[1]))],
          false,
          null);
    } else if (firstVal is Tag) {
      return parseTag(firstVal.value, obj[1], asMapKey);
    }
    // Process rest of array w/o special decoding or interpretation
    ArrayBuilder ab = handler?.arrayBuilder() ?? _arrayBuilder;
    var ar = ab.init();
    ar = ab.add(ar, firstVal);
    for (var e in obj.sublist(1)) {
      ar = ab.add(ar, parseVal(e));
    }
    return ab.complete(ar);
  }

  dynamic decode(String tag, rep) {
    var h = _readHandlers.getHandler(tag);
    if (null != h) {
      return h.fromRep(rep);
    } else {
      return _defaultHandler.fromRep(tag, rep);
    }
  }

  dynamic parseString(dynamic s) {
    if (s is String) {
      if (s.length > 1) {
        switch (s[0]) {
          case ESC:
            {
              switch (s[1]) {
                case ESC:
                case SUB:
                case RESERVED:
                  return s.substring(1);
                case TAG:
                  return Tag(s.substring(2));
                default:
                  return decode(s.substring(1, 2), s.substring(2));
              }
            }
          case SUB:
            if (' ' == s[1]) {
              return MAP;
            }
        }
      }
    }
    return s;
  }
}

abstract class DefaultReadHandler<T> {
  T fromRep(String tag, dynamic rep);
}

class TaggedValueReadHandler extends DefaultReadHandler<TaggedValue> {
  @override
  fromRep(tag, rep) => TaggedValue(tag, rep);
}
