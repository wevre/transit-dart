import 'dart:typed_data';
import '../values/big_decimal.dart';
import '../values/keyword.dart';
import '../values/link.dart';
import '../values/list.dart';
import '../values/symbol.dart';
import '../values/tagged_value.dart';
import '../values/uuid.dart';
import '../values/uri.dart';

typedef WriteHandlersMap = Map<Type, WriteHandler>;

abstract class WriteHandler<T, R> {
  String tag(T obj);

  R rep(T obj);

  String? stringRep(T obj) => obj.toString();

  bool handles(dynamic obj) {
    return obj is T;
  }
}

class WriteHandlers implements TagProvider {
  final WriteHandlersMap handlers;

  WriteHandler? getHandler(o) {
    WriteHandler? h = handlers[o.runtimeType];

    if (null != h) {
      return h;
    }

    for (h in handlers.values) {
      if (h.handles(o)) {
        return h;
      }
    }

    return null;
  }

  WriteHandlers.json({WriteHandlersMap? customHandlers})
      : handlers = {...defaults, ...?customHandlers} {
    handlers[Map] = MapWriteHandler(this);
  }

  static final WriteHandlersMap defaults = {
    Null: NullWriteHandler(),
    String: ToStringWriteHandler<String>('s'),
    bool: BooleanWriteHandler(),
    int: IntegerWriteHandler(),
    double: DoubleWriteHandler(),
    Uint8List: BinaryWriteHandler(),
    Keyword: KeywordWriteHandler(),
    Symbol: ToStringWriteHandler<Symbol>('\$'),
    BigDecimal: ToStringWriteHandler<BigDecimal>('f'),
    BigInt: ToStringWriteHandler<BigInt>('n'),
    DateTime: TimeWriteHandler(),
    Uuid: ToStringWriteHandler<Uuid>('u'),
    TransitUri: ToStringWriteHandler<TransitUri>('r'),
    List: ArrayWriteHandler(),
    Set: SetWriteHandler(),
    TransitList: ListWriteHandler(),
    Link: LinkWriteHandler(),
    TaggedValue: TaggedValueWriteHandler(),
  };

  @override
  String? getTag(obj) {
    var h = getHandler(obj);
    if (null == h) return null;
    return h.tag(obj);
  }
}

// Type-specific WriteHandler's

abstract class AbstractWriteHandler<T> extends WriteHandler<T, dynamic> {
  final String _tag;

  AbstractWriteHandler(this._tag);

  Type type() => T;

  @override
  String tag(T obj) => _tag;

  @override
  rep(T obj) => obj;
}

// ignore: prefer_void_to_null
class NullWriteHandler extends AbstractWriteHandler<Null> {
  NullWriteHandler() : super('_');

  @override
  rep(obj) => null;

  @override
  stringRep(obj) => '';
}

class ToStringWriteHandler<T> extends AbstractWriteHandler<T> {
  ToStringWriteHandler(String tag) : super(tag);

  @override
  rep(obj) => stringRep(obj);
}

class BooleanWriteHandler extends AbstractWriteHandler<bool> {
  BooleanWriteHandler() : super('?');
}

class IntegerWriteHandler extends AbstractWriteHandler<int> {
  IntegerWriteHandler() : super('i');
}

class DoubleWriteHandler extends AbstractWriteHandler<double> {
  DoubleWriteHandler() : super('d');

  @override
  tag(obj) {
    if (obj.isNaN || obj.isInfinite) {
      return 'z';
    } else {
      return _tag;
    }
  }

  @override
  rep(obj) {
    if (obj.isNaN) {
      return 'NaN';
    } else if (obj.isInfinite) {
      return obj == double.negativeInfinity ? '-INF' : 'INF';
    } else {
      return obj;
    }
  }

  @override
  stringRep(obj) => rep(obj).toString();
}

class BinaryWriteHandler extends AbstractWriteHandler<Uint8List> {
  BinaryWriteHandler() : super('b');
}

class KeywordWriteHandler extends AbstractWriteHandler<Keyword> {
  KeywordWriteHandler() : super(':');

  @override
  rep(obj) => stringRep(obj);

  @override
  stringRep(obj) => obj.toString().substring(1);
}

class TimeWriteHandler extends AbstractWriteHandler<DateTime> {
  TimeWriteHandler() : super('m');

  @override
  rep(obj) => obj.millisecondsSinceEpoch;

  @override
  stringRep(obj) => rep(obj).toString();
}

class ArrayWriteHandler extends AbstractWriteHandler<List> {
  ArrayWriteHandler() : super('array');
}

class MapWriteHandler extends AbstractWriteHandler<Map> {
  final TagProvider _tagProvider;

  MapWriteHandler(this._tagProvider) : super('map');

  bool _stringableKeys(Map m) {
    for (var k in m.keys) {
      String? t = _tagProvider.getTag(k);
      if (null != t && t.length > 1) {
        return false;
      } else if (null == t && k is! String) {
        return false;
      }
    }
    return true;
  }

  @override
  tag(obj) => _stringableKeys(obj) ? 'map' : 'cmap';

  // NOTE: is there some inefficiency here? We call `tag` and it checks all the
  // keys. And then we call `rep` and it again checks all the keys.

  @override
  rep(obj) {
    if (_stringableKeys(obj)) {
      return obj;
    } else {
      var l = [
        ...obj.entries.expand((e) => [e.key, e.value])
      ];
      // var l = [];
      // obj.forEach((key, value) {
      //   l.add(key);
      //   l.add(value);
      // });
      return TaggedValue('array', l);
    }
  }
}

class SetWriteHandler extends AbstractWriteHandler<Set> {
  SetWriteHandler() : super('set');

  @override
  rep(obj) => TaggedValue('array', obj.toList(growable: false));
}

class ListWriteHandler extends AbstractWriteHandler<TransitList> {
  ListWriteHandler() : super('list');

  @override
  rep(obj) => TaggedValue('array', obj.value);
}

class LinkWriteHandler extends AbstractWriteHandler<Link> {
  LinkWriteHandler() : super('link');

  @override
  rep(obj) => obj.toMap();
}

class TaggedValueWriteHandler extends WriteHandler<TaggedValue, dynamic> {
  @override
  tag(obj) => obj.tag;

  @override
  rep(obj) => obj.value;
}

abstract class TagProvider {
  String? getTag(obj);
}
