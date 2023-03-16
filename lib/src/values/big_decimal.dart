import 'package:big_decimal/big_decimal.dart' as big_d;

class BigDecimal {
  final big_d.BigDecimal value;

  BigDecimal(this.value);

  static BigDecimal? tryParse(String rep) {
    try {
      return BigDecimal(big_d.BigDecimal.parse(rep));
    } catch (e) {
      return null;
    }
  }

  @override
  String toString() => value.toString();

  @override
  operator ==(other) => (other is BigDecimal) && (other.value == value);

  @override
  get hashCode => 37 * value.hashCode;
}
