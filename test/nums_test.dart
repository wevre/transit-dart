import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:transit_dart/src/codecs/transit.dart';
import 'package:transit_dart/src/codecs/semantic.dart';

void testConvert() {
  var transit = TransitJsonCodec();
  var object = {"num1": 3.0, "num2": 4.0};
  // Encode object to string.
  var encoded = transit.encoder.convert(object);
  // Decode the object.
  var decoded = transit.decoder.convert(encoded);
  // Roundtrip succes?
  var test = DeepCollectionEquality().equals(object, decoded);
  print('Round trip success? ${test ? 'YES' : 'NO'}');
}

void testQuoted() {
  var transit = TransitJsonCodec();
  var value = "{\"~#'\":\"~t2025-06-27T20:02:41.189Z\"}";
  var decoded = transit.decoder.convert(value);
  print(decoded);
  print('is datetime? ${decoded is DateTime}');
}

void testSeparate() {
  var emitter = SemanticEncoder.json();
  var parser = SemanticDecoder.json();
  dynamic obj = {"num1": 3.0, "num2": 4.0, "now": DateTime.now()};
  var emitted = emitter.convert(obj);
  var encoded = json.encode(emitted);
  var decoded = json.decode(encoded);
  var parsed = parser.convert(decoded);
  print('emitted: $emitted');
  print('encoded: $encoded');
  print('decoded: $decoded');
  print('parsed: $parsed');
}

void main() {
  testQuoted();
  testConvert();
  testSeparate();
  // Set up the object.
}
