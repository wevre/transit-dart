/// We need some documentation here about what the heck this thing does.
abstract class ArrayBuilder<G, A, T> {
  G init();

  G add(G a, T item);

  A complete(G a);
}

class ListBuilderImpl extends ArrayBuilder<List, List, dynamic> {
  @override
  init() => [];

  @override
  add(a, item) => a..add(item);

  @override
  complete(a) => a;
}
