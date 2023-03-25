import 'dart:async';
import 'dart:convert';

/// A [Converter] that splits a [String] into separate JSON forms, emitting a
/// parsed JSON object for each form.
///
/// A JSON form is an object or array delimited by braces `{}` or brackets `[]`,
/// respectively. The Dart-provided [JsonDecoder] will parse only one such form
/// and then closes the stream, giving an error if there are extra characters.
/// This converter overcomes that limitation, accepting multiple forms on the
/// incoming stream and parsing each in turn.
class JsonRepeatDecoder extends Converter<String, dynamic> {
  @override
  convert(String input) {
    return Stream.value(input).transform(JsonStreamTransformer()).toList();
  }

  @override
  Sink<String> startChunkedConversion(Sink sink) => _JsonDecoderSink(sink);
}

class _JsonDecoderSink extends Sink<String> {
  final StreamController<String> _controller;

  _JsonDecoderSink(Sink sink) : _controller = StreamController() {
    _controller.stream.transform(JsonStreamTransformer()).listen((event) {
      sink.add(event);
    });
  }

  @override
  void add(String chunk) {
    _controller.sink.add(chunk);
  }

  @override
  void close() {
    _controller.sink.close();
  }
}

/// Transforms a stream of JSON forms into native Dart objects.
///
/// Note this transformer isn't fastidious. It assumes that the incoming data is
/// already valid JSON, and proceeds with very little ceremony to find the
/// boundary between valid JSON forms. It doesn't check for invalid strings, and
/// it treats brackets and braces as interchangeable. For example, it will
/// consider `["A"\]]` a valid JSON form because it skips the character after
/// the backslah, without asserting that the backslash is inside a string.
/// Likewise `[1,2}` is considered a valid form. Of course neither of those
/// examples, nor any other malformed JSON, will survive the call to
/// [jsonDecode()].
class JsonStreamTransformer extends StreamTransformerBase<String, dynamic> {
  final bool _strict;
  final StringBuffer _buffer = StringBuffer();

  JsonStreamTransformer({bool strict = false}) : _strict = strict;

  static const int _doubleQuote = 34;
  static const int _leftBrace = 123;
  static const int _rightBrace = 125;
  static const int _leftBracket = 91;
  static const int _rightBracket = 93;
  static const int _backslash = 92;

  @override
  Stream bind(Stream<String> stream) async* {
    var skipEscape = false;
    var quoted = false;
    var stackDepth = 0;

    await for (final s in stream) {
      var sliceStart = 0;
      for (var i = 0; i < s.length; i++) {
        var char = s.codeUnitAt(i);
        // If prev char was escape, then skip this one.
        if (skipEscape) {
          skipEscape = false;
          continue;
        }
        // Check for interesting chars.
        switch (char) {
          case _doubleQuote:
            quoted = !quoted;
            continue;
          case _leftBrace:
          case _leftBracket:
            if (!quoted && 0 == stackDepth++ && !_strict) {
              sliceStart = i;
              _buffer.clear();
            }
            continue;
          case _rightBrace:
          case _rightBracket:
            if (quoted) {
              continue;
            } else if (--stackDepth > 0) {
              continue;
            } else {
              break;
            }
          case _backslash:
            skipEscape = true;
            continue;
          default:
            continue;
        }
        // Reached the end of a JSON form.
        var slice = s.substring(sliceStart, i + 1);
        _buffer.write(slice);
        yield jsonDecode(_buffer.toString());
        _buffer.clear();
        sliceStart = i + 1;
      }
      // If didn't exhaust the full string, hold the tail in the buffer.
      if (sliceStart < s.length) {
        _buffer.write(s.substring(sliceStart));
      }
    }
  }
}

/// A [Converter] that encodes multiple JSON objects to strings.
///
/// The Dart-provided [JsonEncoder] closes its underlying stream after encoding
/// JSON object, which is annoying. This converter stays open for business.
class JsonRepeatEncoder extends Converter<dynamic, String> {
  @override
  String convert(input) => jsonEncode(input);

  @override
  Sink startChunkedConversion(Sink<String> sink) => _JsonCombinerSink(sink);
}

class _JsonCombinerSink extends ChunkedConversionSink<dynamic> {
  final Sink _sink;

  _JsonCombinerSink(this._sink);

  @override
  void add(chunk) {
    _sink.add(jsonEncode(chunk));
  }

  @override
  void close() {
    _sink.close();
  }
}
