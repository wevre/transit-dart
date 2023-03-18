import 'package:collection/collection.dart';

import 'cacher.dart';
import 'constants.dart';
import 'handlers/array_builder.dart';
import 'handlers/map_builder.dart';
import 'handlers/read_handlers.dart';
import 'values/tag.dart';
import 'values/tagged_value.dart';

abstract class Parser {
  final ReadHandlers _readHandlers;
  late final CacheDecoder _cache;
  late final DefaultReadHandler _defaultHandler;
  late final MapBuilder _mapBuilder;
  late final ArrayBuilder _listBuilder;

  Parser(this._readHandlers,
      {CacheDecoder? cache,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? listBuilder}) {
    _cache = cache ?? CacheDecoder();
    _defaultHandler = defaultHandler ?? TaggedValueReadHandler();
    _mapBuilder = mapBuilder ?? MapBuilderImpl();
    _listBuilder = listBuilder ?? ListBuilderImpl();
  }

  parse(obj) {
    _cache.init();
    return parseVal(obj);
  }

  parseVal(obj, {bool asMapKey = false});
  parseMap(Map obj, bool asMapKey, MapReadHandler? handler);
  parseArray(List obj, bool asMapKey, ArrayReadHandler? handler);

  decode(String tag, rep) {
    var h = _readHandlers.getHandler(tag);
    if (null != h) {
      return h.fromRep(rep);
    } else {
      return _defaultHandler.fromRep(tag, rep);
    }
  }

  parseString(s) {
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

class JsonParser extends Parser {
  JsonParser(super.readHandlers,
      {super.cache, super.defaultHandler, super.listBuilder, super.mapBuilder});

  @override
  parseVal(obj, {bool asMapKey = false}) {
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

  @override
  parseMap(obj, bool asMapKey, MapReadHandler? handler) {
    MapBuilder mr = handler?.mapBuilder() ?? _mapBuilder;
    var mb = mr.init();
    for (var e in obj.entries) {
      var key = parseVal(e.key, asMapKey: true);
      if (key is Tag) {
        return parseTag(key.value, e.value, asMapKey);
      } else {
        mb = mr.add(mb, key, parseVal(e.value));
      }
    }
    return mr.complete(mb);
  }

  parseEntries(List<MapEntry> objs, bool asMapKey, MapReadHandler? handler) {
    MapBuilder mr = handler?.mapBuilder() ?? _mapBuilder;
    var mb = mr.init();
    for (var e in objs) {
      mb = mr.add(mb, parseVal(e.key, asMapKey: true),
          parseVal(e.value, asMapKey: false));
    }
    return mr.complete(mb);
  }

  @override
  parseArray(obj, bool asMapKey, ArrayReadHandler? handler) {
    if (obj.isEmpty) {
      // Make an empty list with the default Array/ListBuilder
      ArrayBuilder ar = handler?.arrayBuilder() ?? _listBuilder;
      return ar.complete(ar.init());
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
    ArrayBuilder ar = handler?.arrayBuilder() ?? _listBuilder;
    var ab = ar.init();
    ab = ar.add(ar.init(), firstVal);
    for (var e in obj.sublist(1)) {
      ab = ar.add(ab, parseVal(e));
    }
    return ar.complete(ab);
  }
}

class MsgpackParser extends Parser {
  MsgpackParser(super.readHandlers, {super.cache, super.defaultHandler, super.listBuilder, super.mapBuilder})


  @override
  parseArray(List obj, bool asMapKey, ArrayReadHandler? handler) {
    // TODO: implement parseArray
    throw UnimplementedError();
  }

  @override
  parseMap(Map obj, bool asMapKey, MapReadHandler? handler) {
    // This one's tricky because we have no control over the order of the map
    // entries if they are parsed directly by msgpack_dart. I'm sort of thinking
    // the solution is to fork that library and provide an opportunity to
    // specify the Map instance we want to use.
    // TODO: implement parseMap
    throw UnimplementedError();
  }

  @override
  parseVal(obj, {bool asMapKey = false}) {
    // TODO: implement parseVal
    throw UnimplementedError();
  }}

abstract class DefaultReadHandler<T> {
  T fromRep(String tag, dynamic rep);
}

class TaggedValueReadHandler extends DefaultReadHandler<TaggedValue> {
  @override
  fromRep(tag, rep) => TaggedValue(tag, rep);
}
