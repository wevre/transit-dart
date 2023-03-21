import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:transit_dart/src/converters.dart';
import 'package:transit_dart/src/json.dart';
import 'package:transit_dart/src/msgpack.dart';

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
}

Future<void> main() async {
  // Some objects to work with.
  var objects = [
    "hello",
    [
      "A",
      "B",
      null,
      true,
      [0, 0],
      3.4
    ],
    {"42": "the answer"},
  ];

  final encoder = MsgpackEncoder();

  for (final o in objects) {
    Uint8List bytes = encoder.convert(o);
    print('object is $o');
    print('encoded is ${bytesToHex(bytes)}');
  }
}
