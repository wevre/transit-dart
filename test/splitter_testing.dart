import 'dart:convert';

import 'package:transit_dart/src/json_splitter.dart';

void main() {
  var buffer = StringBuffer();
  var objs = [
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
  for (var obj in objs) {
    buffer.write(jsonEncode(obj));
  }
  // NOTE: This extra stuff will get ignored by the splitter, unless we set
  // `strict: true` in the constructor call, then it will cause an error.
  buffer.write("[1,3");
  print(buffer.toString());
  Stream.value(buffer.toString()).transform(JsonSplitter()).forEach((element) {
    print(element);
  });
}
