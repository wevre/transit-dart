class Keyword {
  late final String ns;
  late final String name;

  Keyword(String nsname) {
    var i = nsname.indexOf('/');
    if (-1 == i) {
      ns = '';
      name = nsname;
    } else {
      ns = nsname.substring(0, i);
      name = nsname.substring(i + 1);
    }
  }

  @override
  String toString() => ':${ns.isEmpty ? '' : '$ns/'}$name';

  String getNamespace() => ns;
  String getName() => name;
}
