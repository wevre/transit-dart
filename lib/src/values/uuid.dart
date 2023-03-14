class Uuid {
  final String value;

  Uuid(this.value);

  @override
  toString() => value;

  @override
  operator ==(other) => (other is Uuid) && (other.value == value);

  @override
  get hashCode => 29 * value.hashCode;
}
