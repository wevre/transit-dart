class Float {
  final double value;

  Float(this.value);

  @override
  String toString() => value.toString();

  @override
  operator ==(other) => (other is Float) && (other.value == value);

  @override
  int get hashCode => 41 * value.hashCode;
}
