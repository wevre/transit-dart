import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:transit_dart/src/codecs/transit.dart';
import 'package:transit_dart/src/codecs/semantic.dart';

Future<void> test_convert() async {
   var transit = TransitJsonCodec();
   var object = {"num1": 3.0, "num2": 4.0};
   print('object: $object');
   // Encode object to string.
   var encoded = await transit.encoder.convert(object);
   print('encoded: $encoded is of type ${encoded.runtimeType}');
   print('decoder is ${transit.decoder}');
   // Decode the object.
   var decoded = await transit.decoder.convert(encoded);
   print('decoded: $decoded');
   // Roundtrip succes?
   var test = DeepCollectionEquality().equals(object, await decoded);
   print('Round trip success? ${test ? 'YES' : 'NO'}');
}

void test_separate() {
  var emitter = SemanticEncoder.json();
  var parser = SemanticDecoder.json();
  dynamic obj = {"num1": 3.0, "num2": 4.0};
  print('obj is `$obj`');
  var emitted = emitter.convert(obj);
  print('emitted is `$emitted`');
  var encoded = json.encode(emitted);
  print('encoded is `$encoded`');
  var decoded = json.decode(encoded);
  print('decoded is `$decoded`');
  var parsed = parser.convert(decoded);
  print('parsed is `$parsed`');
  print('Equal? ${DeepCollectionEquality().equals(parsed, obj)}');
}

Future<void> main() async {
   test_convert();
   //test_separate();
   // Set up the object.
}
