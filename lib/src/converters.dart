import 'dart:convert';

import 'cacher.dart';
import 'emitter.dart';
import 'handlers/array_reader.dart';
import 'handlers/map_reader.dart';
import 'handlers/read_handlers.dart';
import 'handlers/write_handlers.dart';
import 'parser.dart';

class TransitDecoder extends Converter {
  final Parser parser;

  TransitDecoder.json(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapReader? mapBuilder,
      ArrayReader? listBuilder})
      : parser = JsonParser(ReadHandlers.json(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            listBuilder: listBuilder);

  TransitDecoder.verboseJson(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapReader? mapBuilder,
      ArrayReader? listBuilder})
      : parser = JsonParser(ReadHandlers.json(customHandlers: customHandlers),
            cache: CacheDecoder(active: false),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            listBuilder: listBuilder);

  TransitDecoder.messagePack() : parser = JsonParser(ReadHandlers.json());

  @override
  convert(input) => parser.parse(input);

  @override
  Sink startChunkedConversion(Sink sink) => sink;
}

class TransitEncoder extends Converter {
  final Emitter emitter;

  TransitEncoder.json({WriteHandlersMap? customHandlers})
      : emitter =
            JsonEmitter(WriteHandlers.json(customHandlers: customHandlers));

  @override
  convert(input) => emitter.emit(input);

  // I'm not sure this is technically correct. It seems like we should return a
  // sink that takes in events/objects in its `add` method, calls `emit` on
  // them, and then shoves them over into the output `sink`.
  @override
  Sink startChunkedConversion(Sink sink) => sink;
}
