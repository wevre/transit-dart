import 'dart:convert';
import 'dart:typed_data';

import 'json.dart';
import 'msgpack.dart';
import 'semantic.dart';

export 'semantic.dart'
    show
        DefaultReadHandler,
        ArrayBuilder,
        MapBuilder,
        ReadHandler,
        ArrayReadHandler,
        ReadHandlersMap,
        Class,
        WriteHandler,
        WriteHandlersMap;

abstract class TransitCodec<T> extends Codec<dynamic, T> {
  final SemanticDecoder _semanticDecoder;
  final SemanticEncoder _semanticEncoder;
  final Converter<T, dynamic> _wireDecoder;
  final Converter<dynamic, T> _wireEncoder;

  TransitCodec(this._semanticDecoder, this._semanticEncoder, this._wireDecoder,
      this._wireEncoder);

  @override
  Converter<T, dynamic> get decoder => _wireDecoder.fuse(_semanticDecoder);

  @override
  Converter<dynamic, T> get encoder => _semanticEncoder.fuse(_wireEncoder);
}

class TransitJsonCodec extends TransitCodec<String> {
  TransitJsonCodec(
      {ReadHandlersMap? customReadHandlers,
      WriteHandlersMap? customWriteHandlers,
      DefaultReadHandler? defaultReadHandler, // coming from parser.dart
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : super(
            SemanticDecoder.json(
                customHandlers: customReadHandlers,
                defaultHandler: defaultReadHandler,
                mapBuilder: mapBuilder,
                arrayBuilder: arrayBuilder),
            SemanticEncoder.json(customHandlers: customWriteHandlers),
            JsonRepeatDecoder(),
            JsonRepeatEncoder());
}

class TransitJsonVerboseCodec extends TransitCodec<String> {
  TransitJsonVerboseCodec(
      {ReadHandlersMap? customReadHandlers,
      WriteHandlersMap? customWriteHandlers,
      DefaultReadHandler? defaultReadHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : super(
            SemanticDecoder.jsonVerbose(
                customHandlers: customReadHandlers,
                defaultHandler: defaultReadHandler,
                mapBuilder: mapBuilder,
                arrayBuilder: arrayBuilder),
            SemanticEncoder.jsonVerbose(customHandlers: customWriteHandlers),
            JsonRepeatDecoder(),
            JsonRepeatEncoder());
}

class TransitMessagePackCodec extends TransitCodec<Uint8List> {
  TransitMessagePackCodec(
      {ReadHandlersMap? customReadHandlers,
      WriteHandlersMap? customWriteHandlers,
      DefaultReadHandler? defaultReadHandler,
      MapBuilder? mapBuilder,
      ArrayBuilder? arrayBuilder})
      : super(
            SemanticDecoder.messagePack(
                customHandlers: customReadHandlers,
                defaultHandler: defaultReadHandler,
                mapBuilder: mapBuilder,
                arrayBuilder: arrayBuilder),
            SemanticEncoder.messagePack(customHandlers: customWriteHandlers),
            MessagePackDecoder(),
            MessagePackEncoder());
}
