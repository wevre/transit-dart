import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
}

/// Roundtrip test of MessagePack coders.
///
/// Note that we override the default setting and parse maps as true maps, not
/// as transit map-as-array values with the '^ ' marker.
Future<void> testMessagePack() async {
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

  final encoder = MessagePackEncoder();
  final decoder = MessagePackDecoder();

  for (final o in objects) {
    var bytes = encoder.convert(o);
    var obj = decoder.convert(bytes);
    expect(obj, equals(o));
  }
}

void main() {
  test('MessagePack coders round trip', testMessagePack);
}
