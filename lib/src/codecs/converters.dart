import 'dart:convert';

import 'cacher.dart';
import 'emitter.dart';
import '../handlers/array_builder.dart';
import '../handlers/map_builder.dart';
import '../handlers/read_handlers.dart';
import '../handlers/write_handlers.dart';
import 'parser.dart';

/// A [Converter] to decode transit-formatted JSON objects into native Dart
/// objects.
class TransitDecoder extends Converter {
  final Parser _parser;

  /// Returns a `TransitDecoder` for parsing transit-formatted JSON objects.
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
  /// Dart object is handled by this `TransitDecoder`.
  ///
  /// Here is an example of using a [JsonRepeatDecoder] (which processes a
  /// sequence of JSON strings) in connection with a `TransitDecoder` to parse
  /// incoming transit data from `stdin`.
  ///
  /// ```dart
  /// stdin
  ///     .transform(utf8.decoder)
  ///     .transform(JsonSplitter())
  ///     .transform(TransitDecoder.json())
  ///     .forEach((obj) {
  ///   print('parsed object is $obj');
  /// });
  /// ```
  ///
  /// Optional parameters affect the behavior of `TransitDecoder`. Custom
  /// [ReadHandler]s and tags can be supplied as a map in [customHandlers]. The
  /// [mapBuilder] and [arrayBuilder], if supplied, allow libraries layered on
  /// top of `transit-dart` to hook into the construction of `Array` and `Map`
  /// objects and generate objects appropriate for the target library. A
  /// [defaultHandler] is called when no [ReadHandler] is found for a given tag.
  TransitDecoder.json(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : _parser = Parser(ReadHandlers.json(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            arrayBuilder: arrayBuilder);

  TransitDecoder.verboseJson(
      {ReadHandlersMap? customHandlers,
      DefaultReadHandler? defaultHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : _parser = Parser(ReadHandlers.json(customHandlers: customHandlers),
            defaultHandler: defaultHandler,
            mapBuilder: mapBuilder,
            arrayBuilder: arrayBuilder);

  TransitDecoder.messagePack(
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
  Sink startChunkedConversion(Sink sink) => _TransitSink(sink, _parser.parse);
}

/// A [Converter] to encode native Dart objects into transit-formatted JSON
/// objects.
class TransitEncoder extends Converter {
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
  TransitEncoder.json({WriteHandlersMap? customHandlers})
      : _emitter =
            JsonEmitter(WriteHandlers.json(customHandlers: customHandlers));

  TransitEncoder.verboseJson({WriteHandlersMap? customHandlers})
      : _emitter = JsonEmitter(
            WriteHandlers.json(customHandlers: customHandlers),
            cache: CacheEncoder(active: false));

  TransitEncoder.messagePack({WriteHandlersMap? customHandlers})
      : _emitter = MessagePackEmitter(
            WriteHandlers.messagePack(customHandlers: customHandlers));

  @override
  convert(input) => _emitter.emit(input);

  @override
  Sink startChunkedConversion(Sink sink) => _TransitSink(sink, _emitter.emit);
}

class _TransitSink extends ChunkedConversionSink<dynamic> {
  final Sink _sink;
  final Function(dynamic) _convert;

  _TransitSink(this._sink, this._convert);

  @override
  void add(chunk) {
    _sink.add(_convert(chunk));
  }

  @override
  void close() {
    _sink.close();
  }
}
