import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:transit_dart/src/converters.dart';
import 'package:transit_dart/src/json.dart';
import 'package:transit_dart/src/msgpack.dart';

// NOTE: for testing purposes, might want to call this with
//    roundtripe.exe < sample-file.txt 2>/dev/null
// to not mix the stderr writes with stdout writes.

Future<void> main(List<String> args) async {
  if ('json' == args[0]) {
    jsonRoundtrip();
  } else if ('json-verbose' == args[0]) {
    verboseRoundtrip();
  } else if ('msgpack' == args[0]) {
    msgpackRoundtrip();
  }
}

void jsonRoundtrip() {
  try {
    stdin
        .transform(utf8.decoder)
        .transform(JsonRepeatDecoder())
        .transform(TransitDecoder.json())
        .transform(TransitEncoder.json())
        .transform(JsonRepeatEncoder())
        .transform(utf8.encoder)
        .pipe(stdout);
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}

void verboseRoundtrip() {
  try {
    stdin
        .transform(utf8.decoder)
        .transform(JsonRepeatDecoder())
        .transform(TransitDecoder.verboseJson())
        .transform(TransitEncoder.verboseJson())
        .transform(JsonRepeatEncoder())
        .transform(utf8.encoder)
        .pipe(stdout);
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}

void msgpackRoundtrip() {
  try {
    stdin
        .transform(MessagePackDecoder())
        .transform(TransitDecoder.messagePack())
        .transform(TransitEncoder.messagePack())
        .transform(MessagePackEncoder())
        .cast<List<int>>()
        .pipe(stdout);
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}
