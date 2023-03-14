class Symbol {
  int _hash = 0;
  late final String ns;
  late final String name;

  Symbol(String nsname) {
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
  String toString() => '${ns.isEmpty ? '' : '$ns/'}$name';

  @override
  operator ==(other) {
    return (other is Symbol) && (other.ns == ns) && (other.name == name);
  }

  @override
  get hashCode {
    if (_hash == 0) {
      _hash = 17 * toString().hashCode;
    }
    return _hash;
  }
}
