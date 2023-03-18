import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:transit_dart/src/converters.dart';
import 'package:transit_dart/src/json.dart';

// NOTE: for testing purposes, might want to call this with
//    roundtripe.exe < sample-file.txt 2>/dev/null
// to not mix the stderr writes with stdout writes.

Future<void> main(args) async {
  try {
    stdin
        .transform(utf8.decoder)
        .transform(JsonSplitter())
        .transform(TransitDecoder.json())
        .transform(TransitEncoder.json())
        .transform(JsonCombiner())
        .transform(utf8.encoder)
        .pipe(stdout);
  } catch (e) {
    stderr.write('Error in roundtrip: `$e`');
    rethrow;
  }
}
