import 'dart:async';

import 'package:collection/collection.dart';
import 'package:transit_dart/src/converters.dart';
import 'package:transit_dart/src/json.dart';

Future<void> main() async {
  // Some objects to work with.
  var objects = [
    "hello",
    ["A", "B", null, true, 3.4],
    {42: "the answer"}
  ];

  // Encode the objects to a [StringBuffer].
  var buffer = StringBuffer();
  var writer = TransitEncoder.json().fuse(JsonRepeatEncoder());
  for (var e in objects) {
    print('encoding object `$e`');
    buffer.write(writer.convert(e));
  }

  // What does the encoded string look like?
  var encoded = buffer.toString();
  print('encoded is `$encoded`');

  // Decode the objects.
  var reader = JsonRepeatDecoder().fuse(TransitDecoder.json());
  var res = [];
  await Stream.value(encoded).transform(reader).forEach((e) {
    res.add(e);
    print('decoded object is `$e`');
  });

  // Did everything come back same as we sent it?
  var test = DeepCollectionEquality().equals(objects, res);
  print('Round trip success? ${test ? 'YES' : 'NO'}');
}
