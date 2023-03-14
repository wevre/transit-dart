import 'package:collection/collection.dart';

class TransitList {
  final List value;

  TransitList(this.value);

  @override
  toString() => 'TransitList[${value.toString()}]';

  @override
  operator ==(other) =>
      (other is TransitList) &&
      DeepCollectionEquality().equals(other.value, value);

  @override
  get hashCode => 23 * value.hashCode;
}
