import 'dart:typed_data';
import 'tagged_value.dart';

abstract class WriteHandler<T, R> {
  String tag(T obj);

  R rep(T obj);

  String? stringRep(T obj) => obj.toString();

  bool handles(dynamic obj) {
    return obj is T;
  }
}

class WriteHandlersMap extends Object implements TagProvider {
  final Map<Type, WriteHandler> handlers;

  WriteHandler? getHandler(o) {
    WriteHandler? h = handlers[o.runtimeType];

    if (h != null) {
      return h;
    }

    for (h in handlers.values) {
      if (h.handles(o)) {
        return h;
      }
    }

    throw NoHandlerForObjectError(o);
  }

  WriteHandlersMap.json() : handlers = Map.from(defaults) {
    handlers[Map] = MapWriteHandler(this);
  }

  static final defaults = {
    Null: NullWriteHandler(),
    String: StringWriteHandler(),
    bool: BooleanWriteHandler(),
    int: IntegerWriteHandler(),
    double: DoubleWriteHandler(),
    Uint8List: BinaryWriteHandler(),
    List: ArrayWriteHandler(),
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

class StringWriteHandler extends AbstractWriteHandler<String> {
  StringWriteHandler() : super('s');
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
      var l = [];
      obj.forEach((key, value) {
        l.add(key);
        l.add(value);
      });
      return TaggedValue('array', l);
    }
  }
}

class TaggedValueWriteHandler extends WriteHandler<TaggedValue, dynamic> {
  @override
  tag(obj) => obj.tag;

  @override
  rep(obj) => obj.value;
}

class DefaultWriteHandler extends WriteHandler {
  _throwException(obj) {
    throw Exception("Not supported $obj");
  }

  @override
  String tag(obj) {
    return _throwException(obj);
  }

  @override
  rep(obj) {
    return _throwException(obj);
  }

  @override
  String? stringRep(obj) {
    return _throwException(obj);
  }
}

class NoHandlerForObjectError extends Error {
  final obj;
  NoHandlerForObjectError(this.obj);

  toString() => "No handler for object $obj";
}

abstract class TagProvider {
  String? getTag(obj);
}
