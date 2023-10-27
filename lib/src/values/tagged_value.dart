class TaggedValue {
  final String tag;
  final Object value;

  TaggedValue(this.tag, this.value);

  @override
  operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TaggedValue) return false;
    return ((other as TaggedValue).tag == tag) &&
        ((other as TaggedValue).value == value);
  }

  @override
  get hashCode {
    var result = 17;
    result = 31 * result * tag.hashCode;
    result = 31 * result * value.hashCode;
    return result;
  }
}
