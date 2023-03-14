import 'package:collection/collection.dart';

import 'cacher.dart';
import 'constants.dart';
import 'handlers/array_reader.dart';
import 'handlers/map_reader.dart';
import 'handlers/read_handlers.dart';
import 'values/tag.dart';
import 'values/tagged_value.dart';

abstract class Parser {
  final ReadHandlersMap readHandlersMap;
  final CacheDecoder cache;
  late final DefaultReadHandler defaultHandler;
  late final MapReader mapBuilder;
  late final ArrayReader listBuilder;

  Parser(this.readHandlersMap, this.cache,
      {MapReader? mapBuilder,
      ArrayReader? listBuilder,
      DefaultReadHandler? defaultHandler}) {
    this.mapBuilder = mapBuilder ?? MapBuilderImpl();
    this.listBuilder = listBuilder ?? ListBuilderImpl();
    this.defaultHandler = defaultHandler ?? TaggedValueReadHandler();
  }

  parse(obj) => parseVal(obj);

  parseVal(obj, {bool asMapKey = false});
  parseMap(Map obj, bool asMapKey, MapReadHandler? handler);
  parseArray(List obj, bool asMapKey, ArrayReadHandler? handler);

  decode(String tag, rep) {
    var h = readHandlersMap.getHandler(tag);
    if (null != h) {
      return h.fromRep(rep);
    } else {
      return defaultHandler.fromRep(tag, rep);
    }
  }

  // This method used by the cache decoder. Interesting, there is nothing here
  // that is tied to the parser (other than it is a task belonging to the
  // parser) but it's not like the cacher would have
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
  JsonParser(super.readHandlersMap, super.cache);

  @override
  parseVal(obj, {bool asMapKey = false}) {
    if (obj is Map) {
      return parseMap(obj, asMapKey, null);
    } else if (obj is List) {
      return parseArray(obj, asMapKey, null);
    } else if (obj is String) {
      return cache.convert(obj, asMapKey: asMapKey, parser: this);
    } else {
      return obj;
    }
  }

  dynamic parseTag(String tag, dynamic obj, bool asMapKey) {
    ReadHandler? valHandler = readHandlersMap.getHandler(tag);
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
    MapReader mr = handler?.mapReader() ?? mapBuilder;
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
    MapReader mr = handler?.mapReader() ?? mapBuilder;
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
      ArrayReader ar = handler?.arrayReader() ?? listBuilder;
      return ar.complete(ar.init());
    }
    var firstVal = parseVal(obj[0], asMapKey: asMapKey);
    if (MAP == firstVal) {
      // NO! this won't work because converting it into a MAP does not
      // preserve the order of the entries, which screws up the cache.
      // TODO: Let's create a parseEntries method that knows it is spitting
      // out a map, but it's input is an ordered list of map entries.
      return parseEntries(
          [...obj.sublist(1).slices(2).map((e) => MapEntry(e[0], e[1]))],
          false,
          null);
    } else if (firstVal is Tag) {
      return parseTag(firstVal.value, obj[1], asMapKey);
    }
    // Process rest of array w/o special decoding or interpretation
    ArrayReader ar = handler?.arrayReader() ?? listBuilder;
    var ab = ar.init();
    ab = ar.add(ar.init(), firstVal);
    for (var e in obj.sublist(1)) {
      ab = ar.add(ab, parseVal(e));
    }
    return ar.complete(ab);
  }
}

abstract class DefaultReadHandler<T> {
  T fromRep(String tag, dynamic rep);
}

class TaggedValueReadHandler extends DefaultReadHandler<TaggedValue> {
  @override
  fromRep(tag, rep) => TaggedValue(tag, rep);
}
