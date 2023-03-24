import 'dart:async';
import 'dart:typed_data';

import 'package:transit_dart/src/msgpack.dart';

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
}

Future<void> main() async {
  // Some objects to work with.
  var objects = [
    null,
    "hello",
    [
      "A",
      "B",
      null,
      true,
      [0, 0],
      3.4,
      0x1FFFF,
      -5
    ],
    {"42": "the answer"},
  ];

  Stream.fromIterable(objects)
      .transform(MessagePackEncoder())
      .cast<List<int>>()
      .transform(MessagePackDecoder())
      .forEach((e) {
    print('deserialized obj is `$e`');
  });

  // final encoder = MsgpackEncoder();

  // List<List<int>> encoded = [];
  // for (final o in objects) {
  //   Uint8List bytes = encoder.convert(o);
  //   encoded.add(bytes);
  //   print('object is $o, encoded as ${bytesToHex(bytes)}');
  // }

  // Stream.fromIterable(encoded).transform(MsgpackDeserializer()).forEach((e) {
  //   print('deserialized obj is `$e`');
  // });
}
