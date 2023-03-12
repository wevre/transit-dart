class Uuid {
  final String value;

  Uuid(this.value);

  @override
  toString() => value;
}

void convertUuid() {
  //var uuid = yuli_uuid.Uuid();
  //var s = uuid.v1();
  var s = '40347440-c08b-11ed-a0ad-cd95d606ca0b';
  var hex = s.replaceAll('-', '');
  var hi = BigInt.parse(hex.substring(0, 16), radix: 16);
  var lo = BigInt.parse(hex.substring(16), radix: 16);
  print(s);
  print(hex);
  print(hi);
  print(lo);
  var sHi = hi.toRadixString(16);
  var sLo = lo.toRadixString(16);
  var c = '$sHi$sLo';
  print(sHi);
  print(sLo);
  print(c.length);
  var u =
      '${c.substring(0, 8)}-${c.substring(8, 12)}-${c.substring(12, 16)}-${c.substring(16, 20)}-${c.substring(20)}';
  print(u);
}
