import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:test/test.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';

/// Tests taken from [msgpack2](https://github.com/butlermatt/msgpack2)

var isString = predicate((e) => e is String, 'is a String');
var isInt = predicate((e) => e is int, 'is an int');
var isMap = predicate((e) => e is Map, 'is a Map');
var isList = predicate((e) => e is List, 'is a List');

void main() {
  test("Test Pack null", packNull);

  group("Test Pack Boolean", () {
    test("Pack boolean false", packFalse);
    test("Pack boolean true", packTrue);
  });

  group("Test Pack Ints", () {
    test("Pack Positive FixInt", packPositiveFixInt);
    test("Pack Negative FixInt", packFixedNegative);
    test("Pack Uint8", packUint8);
    test("Pack Uint16", packUint16);
    test("Pack Uint32", packUint32);
    test("Pack Uint64", packUint64);
    test("Pack Int8", packInt8);
    test("Pack Int16", packInt16);
    test("Pack Int32", packInt32);
    test("Pack Int64", packInt64);
  });

  group("Test Pack Floats", () {
    test("Pack Float64 (double)", packDouble);
  });

  test("Pack 5-character string", packString5);
  test("Pack 22-character string", packString22);
  test("Pack 256-character string", packString256);
  test("Pack string array", packStringArray);
  test("Pack int-to-string map", packIntToStringMap);

  test("Test Unpack Null", unpackNull);

  group("Test Unpack boolean", () {
    test("Unpack boolean false", unpackFalse);
    test("Unpack boolean true", unpackTrue);
  });

  group("Test Unpack Ints", () {
    test("Unpack Positive FixInt", unpackPositiveFixInt);
    test("Unpack Negative FixInt", unpackNegativeFixInt);
    test("Unpack Uint8", unpackUint8);
    test("Unpack Uint16", unpackUint16);
    test("Unpack Uint32", unpackUint32);
    test("Unpack Uint64", unpackUint64);
    test("Unpack Int8", unpackInt8);
    test("Unpack Int16", unpackInt16);
    test("Unpack Int32", unpackInt32);
    test("Unpack Int64", unpackInt64);
  });

  group("Test Unpack Floats", () {
    test("Unpack Float32", unpackFloat32);
    test("Unpack Float64 (double)", unpackDouble);
  });

  test("Unpack 5-character string", unpackString5);
  test("Unpack 22-character string", unpackString22);
  test("Unpack 256-character string", unpackString256);
  test("Unpack string array", unpackStringArray);
  test("Unpack int-to-string map", unpackIntToStringMap);

  group("Test Large Array and Map", () {
    test("Large Array", largeArray);
    test("Very Large Array", veryLargeArray);
    test("Large Map", largeMap);
    test("Very Large Map", veryLargeMap);
  });
}

var encoder = MessagePackEncoder();
var decoder = MessagePackDecoder();

void largeArray() {
  final list = <String>[];
  for (int i = 0; i < 16; ++i) {
    list.add("Item $i");
  }

  final serialized = encoder.convert(list);
  List deserialized = decoder.convert(serialized);
  expect(deserialized, list);
}

void veryLargeArray() {
  final list = <String>[];
  for (int i = 0; i < 65536; ++i) {
    list.add("Item $i");
  }

  final serialized = encoder.convert(list);
  List deserialized = decoder.convert(serialized);
  expect(deserialized, list);
}

void largeMap() {
  final map = <int, String>{};
  for (int i = 0; i < 16; ++i) {
    map[i] = "Item $i";
  }
  final serialized = encoder.convert(map);
  final deserialized = decoder.convert(serialized);
  expect(deserialized, map);
}

void veryLargeMap() {
  final map = <int, String>{};
  for (int i = 0; i < 65536; ++i) {
    map[i] = "Item $i";
  }
  final serialized = encoder.convert(map);
  final deserialized = decoder.convert(serialized);
  expect(deserialized, map);
}

void packNull() {
  List<int> encoded = encoder.convert(null);
  expect(encoded, orderedEquals([0xc0]));
}

void packFalse() {
  List<int> encoded = encoder.convert(false);
  expect(encoded, orderedEquals([0xc2]));
}

void packTrue() {
  List<int> encoded = encoder.convert(true);
  expect(encoded, orderedEquals([0xc3]));
}

void packPositiveFixInt() {
  List<int> encoded = encoder.convert(1);
  expect(encoded, orderedEquals([1]));
}

void packFixedNegative() {
  List<int> encoded = encoder.convert(-16);
  expect(encoded, orderedEquals([240]));
}

void packUint8() {
  List<int> encoded = encoder.convert(128);
  expect(encoded, orderedEquals([204, 128]));
}

void packUint16() {
  List<int> encoded = encoder.convert(32768);
  expect(encoded, orderedEquals([205, 128, 0]));
}

void packUint32() {
  List<int> encoded = encoder.convert(2147483648);
  expect(encoded, orderedEquals([206, 128, 0, 0, 0]));
}

void packUint64() {
  List<int> encoded = encoder.convert(9223372036854775807);
  expect(encoded, orderedEquals([207, 127, 255, 255, 255, 255, 255, 255, 255]));
}

void packInt8() {
  List<int> encoded = encoder.convert(-128);
  expect(encoded, orderedEquals([208, 128]));
}

void packInt16() {
  List<int> encoded = encoder.convert(-32768);
  expect(encoded, orderedEquals([209, 128, 0]));
}

void packInt32() {
  List<int> encoded = encoder.convert(-2147483648);
  expect(encoded, orderedEquals([210, 128, 0, 0, 0]));
}

void packInt64() {
  List<int> encoded = encoder.convert(-9223372036854775808);
  expect(encoded, orderedEquals([211, 128, 0, 0, 0, 0, 0, 0, 0]));
}

void packDouble() {
  List<int> encoded = encoder.convert(3.14);
  expect(encoded,
      orderedEquals([0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f]));
}

void packString5() {
  List<int> encoded = encoder.convert("hello");
  expect(encoded, orderedEquals([165, 104, 101, 108, 108, 111]));
}

void packString22() {
  List<int> encoded = encoder.convert("hello there, everyone!");
  expect(
      encoded,
      orderedEquals([
        182,
        104,
        101,
        108,
        108,
        111,
        32,
        116,
        104,
        101,
        114,
        101,
        44,
        32,
        101,
        118,
        101,
        114,
        121,
        111,
        110,
        101,
        33
      ]));
}

void packString256() {
  List<int> encoded = encoder.convert('A' * 256);
  expect(encoded, hasLength(259));
  expect(encoded.sublist(0, 3), orderedEquals([218, 1, 0]));
  expect(encoded.sublist(3, 259), everyElement(65));
}

void packStringArray() {
  List<int> encoded = encoder.convert(["one", "two", "three"]);
  expect(
      encoded,
      orderedEquals([
        147,
        163,
        111,
        110,
        101,
        163,
        116,
        119,
        111,
        165,
        116,
        104,
        114,
        101,
        101
      ]));
}

void packIntToStringMap() {
  List<int> encoded = encoder.convert({1: "one", 2: "two"});
  expect(encoded,
      orderedEquals([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]));
}

// Test unpacking
void unpackNull() {
  Uint8List data = Uint8List.fromList([0xc0]);
  var value = decoder.convert(data);
  expect(value, isNull);
}

void unpackFalse() {
  Uint8List data = Uint8List.fromList([0xc2]);
  var value = decoder.convert(data);
  expect(value, isFalse);
}

void unpackTrue() {
  Uint8List data = Uint8List.fromList([0xc3]);
  var value = decoder.convert(data);
  expect(value, isTrue);
}

void unpackString5() {
  Uint8List data = Uint8List.fromList([165, 104, 101, 108, 108, 111]);
  var value = decoder.convert(data);
  expect(value, isString);
  expect(value, equals("hello"));
}

void unpackString22() {
  Uint8List data = Uint8List.fromList([
    182,
    104,
    101,
    108,
    108,
    111,
    32,
    116,
    104,
    101,
    114,
    101,
    44,
    32,
    101,
    118,
    101,
    114,
    121,
    111,
    110,
    101,
    33
  ]);
  var value = decoder.convert(data);
  expect(value, isString);
  expect(value, equals("hello there, everyone!"));
}

void unpackPositiveFixInt() {
  Uint8List data = Uint8List.fromList([1]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(1));
}

void unpackNegativeFixInt() {
  Uint8List data = Uint8List.fromList([240]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(-16));
}

void unpackUint8() {
  Uint8List data = Uint8List.fromList([204, 128]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(128));
}

void unpackUint16() {
  Uint8List data = Uint8List.fromList([205, 128, 0]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(32768));
}

void unpackUint32() {
  Uint8List data = Uint8List.fromList([206, 128, 0, 0, 0]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(2147483648));
}

void unpackUint64() {
  // Dart 2 doesn't support true Uint64 without using BigInt
  Uint8List data =
      Uint8List.fromList([207, 127, 255, 255, 255, 255, 255, 255, 255]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(9223372036854775807));
}

void unpackInt8() {
  Uint8List data = Uint8List.fromList([208, 128]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(-128));
}

void unpackInt16() {
  Uint8List data = Uint8List.fromList([209, 128, 0]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(-32768));
}

void unpackInt32() {
  Uint8List data = Uint8List.fromList([210, 128, 0, 0, 0]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(-2147483648));
}

void unpackInt64() {
  Uint8List data = Uint8List.fromList([211, 128, 0, 0, 0, 0, 0, 0, 0]);
  var value = decoder.convert(data);
  expect(value, isInt);
  expect(value, equals(-9223372036854775808));
}

void unpackFloat32() {
  Uint8List data = Uint8List.fromList([202, 64, 72, 245, 195]);
  var value = decoder.convert(data);
  expect(value.toStringAsPrecision(3), equals('3.14'));
}

void unpackDouble() {
  Uint8List data = Uint8List.fromList(
      [0xcb, 0x40, 0x09, 0x1e, 0xb8, 0x51, 0xeb, 0x85, 0x1f]);
  var value = decoder.convert(data);
  expect(value, equals(3.14));
}

void unpackString256() {
  Uint8List data = Uint8List.fromList([218, 1, 0, ...List.filled(256, 65)]);
  var value = decoder.convert(data);
  expect(value, isString);
  expect(value, equals('A' * 256));
}

void unpackStringArray() {
  Uint8List data = Uint8List.fromList([
    147,
    163,
    111,
    110,
    101,
    163,
    116,
    119,
    111,
    165,
    116,
    104,
    114,
    101,
    101
  ]);
  var value = decoder.convert(data);
  expect(value, isList);
  expect(value, orderedEquals(["one", "two", "three"]));
}

void unpackIntToStringMap() {
  Uint8List data =
      Uint8List.fromList([130, 1, 163, 111, 110, 101, 2, 163, 116, 119, 111]);
  final value = decoder.convert(data);
  expect(value, isMap);
  expect(value, equals({1: 'one', 2: 'two'}));
}

void unpackSmallDateTime() {
  var data = <int>[0xd7, 0xff, 0, 0, 0, 0, 0, 0, 0, 0];
  var value = decoder.convert(Uint8List.fromList(data));
  expect(value, equals(DateTime.fromMillisecondsSinceEpoch(0)));
  data = <int>[0xd7, 0xff, 47, 175, 8, 0, 91, 124, 180, 16];
  value = decoder.convert(Uint8List.fromList(data));
  expect((value as DateTime).toUtc(),
      equals(DateTime.utc(2018, 8, 22, 0, 56, 56, 200)));
}

void unpackPastDate() {
  var data = <int>[
    0xc7,
    12,
    0xff,
    29,
    205,
    101,
    0,
    255,
    255,
    255,
    255,
    184,
    204,
    121,
    158
  ];

  var value = decoder.convert(Uint8List.fromList(data)) as DateTime;
  expect(value.toUtc(), equals(DateTime.utc(1932, 2, 24, 1, 53, 45, 500)));

  data = <int>[
    199,
    12,
    255,
    0,
    0,
    0,
    0,
    255,
    255,
    255,
    255,
    255,
    255,
    248,
    248
  ];
  value = decoder.convert(Uint8List.fromList(data));
  expect(value.toUtc(), equals(DateTime.utc(1969, 12, 31, 23, 30)));
}
