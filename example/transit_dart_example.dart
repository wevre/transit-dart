import 'dart:async';

import 'package:collection/collection.dart';
import 'package:transit_dart/src/codecs/converters.dart';
import 'package:transit_dart/src/codecs/json.dart';

/// Encodes and decodes some objects. Note that although the objects are stored
/// in a list, they are encoded and decoded separately, each one treated as a
/// top-level object. This is expected behavior for transit and is an example of
/// how transit brokers in not just one, but _streams_ of JSON objects.
Future<void> main() async {
  // Some objects to work with.
  var objects = <dynamic>[
    "hello",
    ["A", "B", null, true, 3.4],
    {42: "the answer"}
  ];
  print('objects: $objects');

  // Encode the objects to a List<String>;
  var writer = TransitEncoder.json().fuse(JsonRepeatEncoder());
  var encoded = await Stream.fromIterable(objects).transform(writer).toList();
  print('encoded: ${encoded.join()}');

  // Decode the objects to a List<dynamic>
  var reader = JsonRepeatDecoder().fuse(TransitDecoder.json());
  var decoded = await Stream.fromIterable(encoded).transform(reader).toList();
  print('decoded: $decoded');

  // Did everything come back same as we sent it?
  var test = DeepCollectionEquality().equals(objects, decoded);
  print('Round trip success? ${test ? 'YES' : 'NO'}');
}
