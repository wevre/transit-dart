class TransitUri {
  final String value;

  TransitUri(this.value);

  @override
  String toString() => value.toString();

  @override
  operator ==(other) => (other is TransitUri) && (other.value == value);

  @override
  get hashCode => 11 * value.hashCode;
}
