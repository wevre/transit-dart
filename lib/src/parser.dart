import 'package:transit_dart2/src/constants.dart';

import 'cacher.dart';
import 'handlers/read_handlers.dart';
import 'values/tag.dart';

abstract class Parser {
  final ReadHandlersMap readHandlersMap;
  final CacheDecoder cache;
  ReadHandler? defaultHandler;

  Parser(this.readHandlersMap, this.cache);

  parse(obj) => parseVal(obj);

  parseVal(obj, {bool asMapKey = false});
  // TODO: JAVA has mapbuilder and listbuilder so it can work with clojure
  // transients. Do we need something as well?
  parseMap(obj, {bool asMapKey = false});
  parseArray(obj, {bool asMapKey = false});

  decode(String tag, rep) {
    var h = readHandlersMap.getHandler(tag) ?? defaultHandler;
    if (h == null) {
      throw Exception('Cannot fromRep $tag: ${rep.toString()}');
    }
    return h.fromRep(rep);
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
  JsonParser(super.readHandlersMap, super.cache);

  @override
  parseVal(obj, {bool asMapKey = false}) {
    // Here we test if the obj is an array, a map, a string, number, null, bool
  }

  @override
  parseArray(obj, {bool asMapKey = false}) {
    // TODO: implement parseArray
    throw UnimplementedError();
  }

  @override
  parseMap(obj, {bool asMapKey = false}) {
    // TODO: implement parseMap
    throw UnimplementedError();
  }
}
