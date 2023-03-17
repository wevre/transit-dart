import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:transit/src/handlers/write_handlers.dart';
import 'package:transit/src/handlers/read_handlers.dart';
import 'package:transit/src/emitter.dart';
import 'package:transit/src/json_splitter.dart';
import 'package:transit/src/parser.dart';
import 'package:transit/src/cacher.dart';

var writeHandlers = WriteHandlersMap.json();
var readHandlers = ReadHandlersMap.json();

// NOTE: for testing purposes, might want to call this with
//    roundtripe.exe < sample-file.txt 2>/dev/null
// to not mix the stderr writes with stdout writes.

Future<void> main(args) async {
  final emitter = JsonEmitter(writeHandlers, CacheEncoder());
  final parser = JsonParser(readHandlers, CacheDecoder());

  // try {
  //   stdin
  //       .transform(utf8.decoder)
  //       .transform(JsonSplitter())
  //       .transform(JsonDecoder()) <-- one shot converter
  //       .transform(TransitDecoder())
  //       .transform(TransitEncoder())
  //       .transform(JsonEncoder())
  //       .transform(utf8.encoder)
  //       .pipe(stdout);
  // } catch (e) {
  //   stderr.write('Error in roundtrip: `$e`');
  // }

  try {
    stdin.transform(utf8.decoder).transform(JsonSplitter()).forEach((obj) {
      //stdout.write('obj is `$obj`');
      //stdout.write(jsonEncode(emitter.emit(parser.parse(jsonDecode(obj)))));
      stdout.write(jsonEncode(emitter.emit(parser.parse(obj))));
    });
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}
