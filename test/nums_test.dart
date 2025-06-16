import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:transit_dart/src/codecs/transit.dart';
import 'package:transit_dart/src/codecs/semantic.dart';

void test_convert() {
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

void test_separate() {
  var emitter = SemanticEncoder.json();
  var parser = SemanticDecoder.json();
  dynamic obj = {"num1": 3.0, "num2": 4.0};
  var emitted = emitter.convert(obj);
  var encoded = json.encode(emitted);
  var decoded = json.decode(encoded);
  var parsed = parser.convert(decoded);
}

void main() {
  test_convert();
  //test_separate();
  // Set up the object.
}
