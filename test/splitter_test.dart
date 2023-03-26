import 'dart:convert';

import 'package:test/test.dart';
import 'package:transit_dart/src/codecs/json.dart';

/// Roundtrip test of JSON data, including some garbage in between forms that
/// (without the `strict` option on JsonRepeatDecoder) will be ignored.
Future<void> testGarbage() async {
  var objects = [
    [
      1,
      2,
      3,
    ],
    [
      "\"a",
      "b",
      "c",
    ],
    {
      "first": 10,
      "second": 20,
    },
  ];
  var encodedWithGarbage = objects.map(jsonEncode).join('--garbage--');
  var decoded = await Stream.value(encodedWithGarbage)
      .transform(JsonRepeatDecoder())
      .toList();
  expect(decoded, equals(objects));
}

void main() {
  test('JsonRepeatEncoder ignores garbage', testGarbage);
}
