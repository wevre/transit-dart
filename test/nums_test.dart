import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:transit_dart/src/codecs/transit.dart';
import 'package:transit_dart/src/codecs/semantic.dart';

Future<void> test_convert() async {
  var transit = TransitJsonCodec();
  var object = {"num1": 3.0, "num2": 4.0};
  // Encode object to string.
  var encoded = await transit.encoder.convert(object);
  // Decode the object.
  var decoded = await transit.decoder.convert(encoded);
  // Roundtrip succes?
  var test = DeepCollectionEquality().equals(object, await decoded);
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

Future<void> main() async {
  test_convert();
  //test_separate();
  // Set up the object.
}
