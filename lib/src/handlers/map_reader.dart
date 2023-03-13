/// We need some documentation here about what the heck this thing does.
abstract class MapReader<G, M, K, V> {
  G init();

  G add(G m, K key, V val);

  M complete(G m);
}

class MapBuilderImpl implements MapReader<Map, Map, dynamic, dynamic> {
  @override
  init() => {};

  @override
  add(m, key, val) {
    m[key] = val;
    return m;
  }

  @override
  complete(m) => m;
}
