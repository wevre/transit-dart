import 'dart:collection';

abstract class MapBuilder<G, M, K, V> {
  // Initialize a new (gestational) map
  G init();
  // Add key and val to the gestational map, return new gestational map, which
  // must be used for the next invocation.
  G add(G m, K key, V val);
  // Convert gestational map into final map and return it.
  M complete(G m);
}

class MapBuilderImpl implements MapBuilder<Map, Map, dynamic, dynamic> {
  @override
  init() => Map();

  @override
  add(m, key, val) {
    m[key] = val;
    return m;
  }

  @override
  complete(m) => m;
}

class Deserializer {
  final ExtDecoder? _extDecoder;
  final MapBuilder _mapBuilder; //<-- this is new
  final codec = Utf8Codec();
  final Uint8List _list;
  final ByteData _data;
  int _offset = 0;

  Deserializer(Uint8List list,
      {ExtDecoder? extDecoder,
      this.copyBinaryData = false,
      MapBuilder? mapBuilder //<-- this is new
      })
      : _list = list,
        _data = ByteData.view(list.buffer, list.offsetInBytes),
        _extDecoder = extDecoder,
        _mapBuilder = mapBuilder ?? MapBuilderImpl(); //<-- this is new

  // ... SKIPPING ...

  // Delegates to `mapBuilder` for actual map construction, always passing in
  // the result of the previous call as input to the next call.
  Map _readMap(int length) {
    var mr = _mapBuilder.init();
    while (length > 0) {
      mr = _mapBuilder.add(mr, decode(), decode());
      --length;
    }
    return _mapBuilder.complete(mr);
  }
}
