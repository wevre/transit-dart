import 'package:transit_dart/src/codecs/transit.dart';

void testOneDate() {
  var transit = TransitJsonVerboseCodec();
  var value = "{\"~#'\":\"~t2000-01-01T12:00:00.000Z\"}";
  var decoded = transit.decoder.convert(value);
  print('decoded is $decoded');
  print('is datetime? ${decoded is DateTime}');
  var encoded = transit.encoder.convert(decoded);
  print('encoded is $encoded');
}

void main() {
  print('date to string is ${DateTime.now().toUtc().toIso8601String()}');
  testOneDate();
}
