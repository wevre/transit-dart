import 'dart:convert';

import 'cacher.dart';
import 'emitter.dart';
import '../handlers/array_builder.dart';
import '../handlers/map_builder.dart';
import '../handlers/read_handlers.dart';
import '../handlers/write_handlers.dart';
import 'parser.dart';

export 'parser.dart' show DefaultReadHandler;
export '../handlers/array_builder.dart' show ArrayBuilder;
export '../handlers/map_builder.dart' show MapBuilder;
export '../handlers/read_handlers.dart'
    show ReadHandler, ArrayReadHandler, ReadHandlersMap;
export '../handlers/write_handlers.dart' show WriteHandler, WriteHandlersMap;

/// A [Converter] to decode transit formatted (i.e. semantic) values into
/// native Dart objects.
class SemanticDecoder extends Converter {
  final Parser _parser;

  /// Returns a `SemanticDecoder` for parsing transit-formatted JSON objects.
  ///
  /// This converter is meant to be chained with a [JsonDecoder] in a pipeline
  /// that converts a JSON string to a Dart native object, as illustrated below.
  ///
  /// ```
  /// [JSON string] ==(a)==> [formatted value] ==(b)==> [Dart native object]
  /// ```
  ///
  /// Above, the conversion (a) from JSON string to a transit formatted value is
  /// accomplished with a [JsonDecoder] and the final conversion (b) to a native
  /// Dart object is handled by this `SemanticDecoder`.
  ///
  /// Here is an example of using a [JsonSplitter] (which processes a sequence
  /// of JSON strings) in connection with a `SemanticDecoder` to parse incoming
  /// transit data from `stdin`.
  ///
  /// ```dart
  /// stdin
  ///     .transform(utf8.decoder)
  ///     .transform(JsonSplitter())
  ///     .transform(SemanticDecoder.json())
  ///     .forEach((obj) {
  ///   print('parsed object is $obj');
  /// });
  /// ```
  ///
  /// Optional parameters affect the behavior of `SemanticDecoder`. Custom
  /// [ReadHandler]s and tags can be bundled into a [ReadHandlersMap] and
  /// supplied in [customHandlers]. The [mapBuilder] and [arrayBuilder], if
  /// supplied, allow libraries layered on top of `transit-dart` to hook into
  /// the construction of `Array` and `Map` objects and generate objects
  /// appropriate for the target library. A [defaultHandler] is called when no
  /// [ReadHandler] is found for a given tag.
  SemanticDecoder.json(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : _parser = Parser(ReadHandlers.json(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            arrayBuilder: arrayBuilder);

  SemanticDecoder.jsonVerbose(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : _parser = Parser(ReadHandlers.json(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            arrayBuilder: arrayBuilder);

  SemanticDecoder.messagePack(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : _parser = Parser(
            ReadHandlers.messagePack(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            arrayBuilder: arrayBuilder);

  @override
  convert(input) => _parser.parse(input);

  @override
  Sink startChunkedConversion(Sink sink) => _SemanticSink(sink, _parser.parse);
}

/// A [Converter] to encode native Dart objects into transit-formatted (i.e.
/// semantic) objects.
class SemanticEncoder extends Converter {
  final Emitter _emitter;

  /// Returns a `TransitEncoder` for emitting transit-formatted JSON objects.
  ///
  /// This converter is meant to be chained with a [JsonEncoder] in a pipeline
  /// that converts a Dart native object into a JSON string, as illustrated
  /// below.
  ///
  /// ```
  /// [Dart native object] ==(a)==> [formatted value] ==(b)==> [JSON string]
  /// ```
  ///
  /// Above, the initial conversion (a) from a Dart object into a transit
  /// formatted value is handled by a `TransitEncoder` and the subsequent
  /// conversion (b) to a JSON string is handled by a [JsonEncoder].
  ///
  /// Here is an example of using a `TransitEncoder` and [JsonRepeatEncoder]
  /// (which processes a sequence of JSON objects) to encode individual objects
  /// to `stdout`.
  ///
  /// ```dart
  ///  var objects = ['A', {null: null, 'foo': true}, 3.14];
  ///  Stream
  ///      .fromIterable(objects)
  ///      .transform(TransitEncoder.json())
  ///      .transform(JsonCombiner())
  ///      .transform(utf8.encoder)
  ///      .pipe(stdout);
  /// ```
  ///
  /// Supply custom handlers as a map in [customHandlers].
  SemanticEncoder.json({WriteHandlersMap? customHandlers})
      : _emitter =
            JsonEmitter(WriteHandlers.json(customHandlers: customHandlers));

  SemanticEncoder.jsonVerbose({WriteHandlersMap? customHandlers})
      : _emitter = JsonEmitter(
            WriteHandlers.json(customHandlers: customHandlers),
            cache: CacheEncoder(active: false));

  SemanticEncoder.messagePack({WriteHandlersMap? customHandlers})
      : _emitter = MessagePackEmitter(
            WriteHandlers.messagePack(customHandlers: customHandlers));

  @override
  convert(input) => _emitter.emit(input);

  @override
  Sink startChunkedConversion(Sink sink) => _SemanticSink(sink, _emitter.emit);
}

class _SemanticSink implements Sink<dynamic> {
  final Sink _sink;
  final Function(dynamic) _convert;

  _SemanticSink(this._sink, this._convert);

  @override
  void add(chunk) {
    _sink.add(_convert(chunk));
  }

  @override
  void close() {
    _sink.close();
  }
}
