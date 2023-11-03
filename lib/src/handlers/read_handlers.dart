import 'dart:convert';
import 'dart:typed_data';
import 'array_builder.dart';
import 'map_builder.dart';

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
    "'": IdentityReadHandler(),
    '_': NullReadHandler(),
    '?': BooleanReadHandler(),
    'i': IntegerReadHandler(),
    'd': DoubleReadHandler(),
    'b': BinaryReadHandler(),
    'm': TimeReadHandler(),
    't': VerboseTimeReadHander(),
    'r': UriReadHandler(),
    'z': SpecialNumberReadHandler(),
    'cmap': CmapReadHandler(),
    'set': SetReadHandler(),
  };
}

abstract class AbstractReadHandler<T> extends ReadHandler<T, dynamic> {}

// ignore: prefer_void_to_null
class NullReadHandler extends AbstractReadHandler<Null> {
  @override
  fromRep(rep) => null;
}

class IdentityReadHandler extends AbstractReadHandler<dynamic> {
  @override
  fromRep(rep) => rep;
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

class TimeReadHandler extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) {
    var m = (rep is int) ? rep : int.parse(rep);
    return DateTime.fromMillisecondsSinceEpoch(m, isUtc: true);
  }
}

class VerboseTimeReadHander extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) => DateTime.parse(rep);
}

class UriReadHandler extends AbstractReadHandler<Uri> {
  @override
  // @TODO: tryParse or parse?
  fromRep(rep) => Uri.parse(rep);
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
