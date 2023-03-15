import 'dart:convert';

// import 'package:fixed/fixed.dart';
// import 'package:collection/collection.dart';

// import 'package:transit_dart/src/handlers/write_handlers.dart';
// import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/json_splitter.dart';
// import 'package:transit_dart/src/emitter.dart';
// import 'package:transit_dart/src/parser.dart';
// import 'package:transit_dart/src/cacher.dart';
// import 'package:transit_dart/src/values/keyword.dart';
// import 'package:transit_dart/src/values/link.dart';
// import 'package:transit_dart/src/values/list.dart';
// import 'package:transit_dart/src/values/symbol.dart';
// import 'package:transit_dart/src/values/uuid.dart';

// var writeHandlers = WriteHandlersMap.json();
// var readHandlers = ReadHandlersMap.json();

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
  buffer.write("[1,3");
  print(buffer.toString());
  var splitter = JsonSplitter();
  var strs = splitter.convert(buffer.toString());
  print(strs);
}
