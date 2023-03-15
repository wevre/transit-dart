import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:transit_dart/src/handlers/write_handlers.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/emitter.dart';
import 'package:transit_dart/src/json_splitter.dart';
import 'package:transit_dart/src/parser.dart';
import 'package:transit_dart/src/cacher.dart';

var writeHandlers = WriteHandlersMap.json();
var readHandlers = ReadHandlersMap.json();

Future<void> main(args) async {
  final emitter = JsonEmitter(writeHandlers, CacheEncoder());
  final parser = JsonParser(readHandlers, CacheDecoder());

  try {
    stdin.transform(utf8.decoder).transform(JsonSplitter()).listen((obj) {
      stderr.write('obj is `$obj`\n\n');
      stdout.write(jsonEncode(emitter.emit(parser.parse(jsonDecode(obj)))));
    });
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}
