class TaggedValue {
  final String tag;
  final Object value;

  TaggedValue(this.tag, this.value);

  @override
  operator ==(other) {
    return (other is TaggedValue) &&
        (other.tag == tag) &&
        (other.value == value);
  }

  @override
  get hashCode {
    var result = 17;
    result = 31 * result * tag.hashCode;
    result = 31 * result * value.hashCode;
    return result;
  }
}
