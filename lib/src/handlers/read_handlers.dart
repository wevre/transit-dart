import 'dart:convert';
import 'dart:typed_data';
import 'array_builder.dart';
import 'map_builder.dart';
import '../values/link.dart';
import '../values/list.dart';
import '../values/uuid.dart';

typedef ReadHandlersMap = Map<String, ReadHandler>;

abstract class ReadHandler<T, R> {
  T fromRep(R rep);
}

class ReadHandlers {
  final ReadHandlersMap _handlers;

  ReadHandler? getHandler(String tag) {
    return _handlers[tag];
  }

  ReadHandlers.json({ReadHandlersMap? customHandlers})
      : _handlers = {..._defaults, ...?customHandlers};

  ReadHandlers.messagePack({ReadHandlersMap? customHandlers})
      : _handlers = {..._defaults, ...?customHandlers};

  static final ReadHandlersMap _defaults = {
    '_': NullReadHandler(),
    '?': BooleanReadHandler(),
    'i': IntegerReadHandler(),
    'd': DoubleReadHandler(),
    'b': BinaryReadHandler(),
    //'\$': SymbolReadHandler(),
    'n': BigIntegerReadHandler(),
    'm': TimeReadHandler(),
    't': VerboseTimeReadHander(),
    'u': UuidReadHandler(),
    'r': UriReadHandler(),
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

class BigIntegerReadHandler extends AbstractReadHandler<BigInt> {
  @override
  fromRep(rep) => BigInt.tryParse(rep)!;
}

class TimeReadHandler extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) {
    var m = (rep is int) ? rep : int.parse(rep);
    return DateTime.fromMillisecondsSinceEpoch(m);
  }
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
      var hi = BigInt.from(l[0]).toUnsigned(64).toRadixString(16);
      var lo = BigInt.from(l[1]).toUnsigned(64).toRadixString(16);
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

class UriReadHandler extends AbstractReadHandler<Uri> {
  @override
  // @TODO: tryParse or parse?
  fromRep(rep) => Uri.parse(rep);
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
  MapBuilder<G, M, dynamic, dynamic> mapBuilder();
}

abstract class ArrayReadHandler<G, A> extends AbstractReadHandler<A> {
  ArrayBuilder<G, A, dynamic> arrayBuilder();
}

class _SetArrayReader extends ArrayBuilder<Set, Set, dynamic> {
  @override
  init() => {};

  @override
  add(a, item) => a..add(item);

  @override
  complete(a) => a;
}

class SetReadHandler extends ArrayReadHandler<Set, Set> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayBuilder() => _SetArrayReader();
}

class _ListArrayReader extends ArrayBuilder<TransitList, TransitList, dynamic> {
  @override
  init() => TransitList([]);

  @override
  add(a, item) => a..value.add(item);

  @override
  complete(a) => a;
}

class ListReadHandler extends ArrayReadHandler<TransitList, TransitList> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayBuilder() => _ListArrayReader();
}

class _CmapArrayReader extends ArrayBuilder<_CmapArrayReader, Map, dynamic> {
  final Map _m = {};
  dynamic _nextKey;
  final _marker = Object();

  _CmapArrayReader() {
    _nextKey = _marker;
  }

  @override
  init() => this;

  @override
  add(a, item) {
    if (_nextKey == _marker) {
      _nextKey = item;
    } else {
      _m[_nextKey] = item;
      _nextKey = _marker;
    }
    return this;
  }

  @override
  complete(a) => _m;
}

class CmapReadHandler extends ArrayReadHandler<_CmapArrayReader, Map> {
  @override
  fromRep(rep) => throw Exception('Unsupported operation fromRep');

  @override
  arrayBuilder() => _CmapArrayReader();
}
