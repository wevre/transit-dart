import 'dart:async';
import 'dart:convert';

import 'combiner.dart';

/// A [Converter] that splits a [String] into separate JSON forms, emitting a
/// parsed JSON object for each form.
///
/// A JSON form is an object or array delimited by braces `{}` or brackets `[]`,
/// respectively. The Dart-provided [JsonDecoder] will parse only one such form
/// and then closes the stream, giving an error if there are extra characters.
/// This converter overcomes that limitation, accepting multiple forms on the
/// incoming stream and parsing each in turn.
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

class JsonFramingDecoder extends Converter<String, String> {
  final bool _strict;
  JsonFramingDecoder(this._strict);

  @override
  String convert(String input) {
    return input;
  }

  @override
  Sink<String> startChunkedConversion(Sink<String> sink) {
    return _JsonFramingSink(sink, _strict);
  }
}

class JsonRepeatDecoder extends Converter<String, dynamic> {
  final Converter<String, dynamic> _converter;

  JsonRepeatDecoder({bool strict = false})
      : _converter = JsonFramingDecoder(strict)
            .fuse(StreamMappingConverter.from(JsonDecoder().convert));

  @override
  dynamic convert(String input) => _converter.convert(input);

  @override
  Sink<String> startChunkedConversion(Sink<dynamic> sink) {
    return _converter.startChunkedConversion(sink);
  }
}

class _JsonFramingSink implements Sink<String> {
  static const int _doubleQuote = 34;
  static const int _leftBrace = 123;
  static const int _rightBrace = 125;
  static const int _leftBracket = 91;
  static const int _rightBracket = 93;
  static const int _backslash = 92;

  final bool _strict;
  final StringBuffer _buffer = StringBuffer();
  var _skipEscape = false;
  var _quoted = false;
  var _stackDepth = 0;
  final Sink<String> _sink;

  _JsonFramingSink(this._sink, this._strict);

  @override
  void add(String s) {
    var sliceStart = 0;
    for (var i = 0; i < s.length; i++) {
      var char = s.codeUnitAt(i);
      // If prev char was escape, then skip this one.
      if (_skipEscape) {
        _skipEscape = false;
        continue;
      }
      // Check for interesting chars.
      switch (char) {
        case _doubleQuote:
          _quoted = !_quoted;
          continue;
        case _leftBrace:
        case _leftBracket:
          if (!_quoted && 0 == _stackDepth++ && !_strict) {
            // when lenient (not strict), discard all characters before the top-level dict/array
            sliceStart = i;
            _buffer.clear();
          }
          continue;
        case _rightBrace:
        case _rightBracket:
          if (_quoted) {
            continue;
          } else if (--_stackDepth > 0) {
            continue;
          } else {
            break;
          }
        case _backslash:
          _skipEscape = true;
          continue;
        default:
          continue;
      }
      // Reached the end of a JSON form.
      var slice = s.substring(sliceStart, i + 1);
      _buffer.write(slice);
      sliceStart = i + 1;
      String read = _buffer.toString();
      _buffer.clear();
      _sink.add(read);
    }
    _buffer.write(s.substring(sliceStart));
  }

  @override
  void close() {
    _buffer.clear();
    _sink.close();
  }
}

/// A [Converter] that encodes multiple JSON objects to strings.
///
/// The Dart-provided [JsonEncoder] closes its underlying stream after encoding
/// JSON object, which is annoying. This converter stays open for business.
class JsonRepeatEncoder extends StreamFnMappingConverter<dynamic, String> {
  JsonRepeatEncoder() : super(JsonEncoder().convert);
}
