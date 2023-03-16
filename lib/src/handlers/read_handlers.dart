import 'dart:convert';
import 'dart:typed_data';
import 'array_reader.dart';
import 'map_reader.dart';
import '../values/big_decimal.dart';
import '../values/keyword.dart';
import '../values/link.dart';
import '../values/list.dart';
import '../values/symbol.dart';
import '../values/uuid.dart';
import '../values/uri.dart';

abstract class ReadHandler<T, R> {
  T fromRep(R rep);
}

class ReadHandlersMap {
  final Map<String, ReadHandler> handlers;

  ReadHandler? getHandler(String tag) {
    return handlers[tag];
  }

  ReadHandlersMap.json() : handlers = Map.from(defaults);

  static final defaults = {
    '_': NullReadHandler(),
    '?': BooleanReadHandler(),
    'i': IntegerReadHandler(),
    'd': DoubleReadHandler(),
    'b': BinaryReadHandler(),
    ':': KeywordReadHandler(),
    '\$': SymbolReadHandler(),
    'f': BigDecimalReadHandler(),
    'n': BigIntegerReadHandler(),
    'm': TimeReadHandler(),
    't': VerboseTimeReadHander(),
    'u': UuidReadHandler(),
    'r': TransitUriReadHandler(),
    'c': CharacterReadHandler(),
    "'": QuotedReadHandler(),
    'z': SpecialNumberReadHandler(),
    'cmap': CmapReadHandler(),
    'list': ListReadHandler(),
    'set': SetReadHandler(),
    'link': LinkReadHandler(),
  };
}

abstract class AbstractReadHandler<T> extends ReadHandler<T, dynamic> {}

// ignore: prefer_void_to_null
class NullReadHandler extends AbstractReadHandler<Null> {
  @override
  fromRep(rep) => null;
}

class BooleanReadHandler extends AbstractReadHandler<bool> {
  @override
  fromRep(rep) => 't' == rep;
}

class IntegerReadHandler extends AbstractReadHandler<int> {
  @override
  fromRep(rep) => int.parse(rep);
}

class DoubleReadHandler extends AbstractReadHandler<double> {
  @override
  fromRep(rep) => double.parse(rep);
}

class BinaryReadHandler extends AbstractReadHandler<Uint8List> {
  @override
  fromRep(rep) => base64.decode(rep);
}

class KeywordReadHandler extends AbstractReadHandler<Keyword> {
  @override
  fromRep(rep) => Keyword(rep);
}

class SymbolReadHandler extends AbstractReadHandler<Symbol> {
  @override
  fromRep(rep) => Symbol(rep);
}

class BigDecimalReadHandler extends AbstractReadHandler<BigDecimal> {
  @override
  fromRep(rep) => BigDecimal.tryParse(rep)!;
}

class BigIntegerReadHandler extends AbstractReadHandler<BigInt> {
  @override
  fromRep(rep) => BigInt.tryParse(rep)!;
}

class TimeReadHandler extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) => DateTime.fromMillisecondsSinceEpoch(int.parse(rep));
}

class VerboseTimeReadHander extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) => DateTime.parse(rep);
}

class UuidReadHandler extends AbstractReadHandler<Uuid> {
  @override
  fromRep(rep) {
    if (rep is String) {
      return Uuid(rep);
    } else if (rep is List) {
      List l = rep;
      var hi = l[0].toRadixString(16);
      var lo = l[1].toRadixString(16);
      var c = '$hi$lo';
      var u =
          '${c.substring(0, 8)}-${c.substring(8, 12)}-${c.substring(12, 16)}'
          '-${c.substring(16, 20)}-${c.substring(20)}';
      return Uuid(u);
    } else {
      throw Error();
    }
  }
}

class TransitUriReadHandler extends AbstractReadHandler<TransitUri> {
  @override
  fromRep(rep) => TransitUri(rep);
}

class CharacterReadHandler extends AbstractReadHandler<String> {
  @override
  fromRep(rep) => rep;
}

class QuotedReadHandler extends AbstractReadHandler<dynamic> {
  @override
  fromRep(rep) => rep;
}

class SpecialNumberReadHandler extends AbstractReadHandler<double> {
  @override
  fromRep(rep) {
    if ('NaN' == rep) {
      return double.nan;
    } else if ('INF' == rep) {
      return double.infinity;
    } else if ('-INF' == rep) {
      return double.negativeInfinity;
    } else {
      throw Error();
    }
  }
}

class LinkReadHandler extends AbstractReadHandler<Link> {
  @override
  fromRep(rep) => Link.fromMap(rep);
}

abstract class MapReadHandler<G, M> extends AbstractReadHandler<M> {
  MapReader<G, M, dynamic, dynamic> mapReader();
}

abstract class ArrayReadHandler<G, A> extends AbstractReadHandler<A> {
  ArrayReader<G, A, dynamic> arrayReader();
}

class _SetArrayReader extends ArrayReader<Set, Set, dynamic> {
  @override
  init() => {};

  @override
  add(a, item) {
    a.add(item);
    return a;
  }

  @override
  complete(a) => a;
}

class SetReadHandler extends ArrayReadHandler<Set, Set> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayReader() => _SetArrayReader();
}

class _ListArrayReader extends ArrayReader<TransitList, TransitList, dynamic> {
  @override
  init() => TransitList([]);

  @override
  add(a, item) {
    a.value.add(item);
    return a;
  }

  @override
  complete(a) => a;
}

class ListReadHandler extends ArrayReadHandler<TransitList, TransitList> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayReader() => _ListArrayReader();
}

class _CmapArrayReader extends ArrayReader<_CmapArrayReader, Map, dynamic> {
  Map m = {};
  dynamic nextKey;

  @override
  init() => this;

  @override
  add(ar, item) {
    if (null != nextKey) {
      m[nextKey] = item;
      nextKey = null;
    } else {
      nextKey = item;
    }
    return this;
  }

  @override
  complete(a) => m;
}

class CmapReadHandler extends ArrayReadHandler<_CmapArrayReader, Map> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayReader() => _CmapArrayReader();
}
