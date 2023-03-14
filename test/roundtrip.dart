import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:transit_dart/src/handlers/write_handlers.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/emitter.dart';
import 'package:transit_dart/src/parser.dart';
import 'package:transit_dart/src/cacher.dart';

Future<dynamic> readJsonFromStdin() async {
  dynamic res;
  final completer = Completer();
  stdin.transform(utf8.decoder).transform(JsonDecoder()).listen(
    (obj) {
      res = obj;
    },
    onDone: () {
      completer.complete();
    },
  );
  await completer.future;
  return res;
}

var writeHandlers = WriteHandlersMap.json();
var readHandlers = ReadHandlersMap.json();

Future<void> main(args) async {
  final emitter = JsonEmitter(writeHandlers, CacheEncoder());
  final parser = JsonParser(readHandlers, CacheDecoder());

  try {
    final json = await readJsonFromStdin();
    var parsed = parser.parse(json);
    var emitted = emitter.emit(parsed);
    stdout.write(jsonEncode(emitted));
  } catch (e) {
    print(e);
    rethrow;
  }
}
