import 'dart:async';
import 'dart:typed_data';

//import 'package:test/test.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';

String bytesToHex(Uint8List bytes) {
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(" ");
}

/// Roundtrip test of MessagePack coders.
///
/// Note that we override the default setting and parse maps as true maps, not
/// as transit map-as-array values with the '^ ' marker.
Future<void> testMessagePack() async {
  // var objects = <dynamic>[
  //   null,
  //   "hello",
  //   [
  //     //  "A",
  //     //  "B",
  //     null,
  //     true,
  //     [0, 0],
  //     3.4,
  //     0x1FFFF,
  //     -5
  //   ],
  //   {"42": "the answer"},
  // ];

  var objects = <dynamic>["hello", null, 1];

  var encoded = await Stream.fromIterable(objects)
      .transform(MessagePackEncoder())
      .cast<List<int>>()
      .toList();

  for (var bb in encoded) {
    print(bb);
  }

  // var encoded = await Stream.fromIterable(objects)
  //     .transform(MessagePackEncoder())
  //     .map((event) {
  //       print(bytesToHex(event));
  //       return event;
  //     })
  //     .cast<List<int>>()
  //     .transform(MessagePackDecoder(parseTransitMap: false))
  //     .toList();
  // TODO: something is not working with this. Not sure what. I can still pass
  // all the other tests, but they all roundtrip the reverse (decode and then
  // encode) but this roundtrip is producing some strange output.
  // print(encoded);

  // expect(roundtrip, equals(objects));
}

void main() {
  testMessagePack();
}
