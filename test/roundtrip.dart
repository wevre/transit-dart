import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:transit_dart/src/codecs/semantic.dart';
import 'package:transit_dart/src/codecs/json.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';

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
        .transform(SemanticDecoder.json())
        .transform(SemanticEncoder.json())
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
        .transform(SemanticDecoder.jsonVerbose())
        .transform(SemanticEncoder.jsonVerbose())
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
        .cast<Uint8List>()
        .transform(MessagePackDecoder())
        .transform(SemanticDecoder.messagePack())
        .transform(SemanticEncoder.messagePack())
        .transform(MessagePackEncoder())
        .cast<List<int>>()
        .pipe(stdout);
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}
