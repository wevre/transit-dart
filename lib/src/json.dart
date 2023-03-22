import 'dart:convert';

/// A [StringTransformer] that splits a [String] into separate JSON forms,
/// emitting a JSON object for each form.
///
/// A JSON form is an object or array delimited by braces `{}` or brackets
/// `[]`, respectively. The Dart-provided [JsonDecoder] will parse only one such
/// form and give an error upon encountering extra characters. This Transformer
/// overcomes that limitation, accepting multiple forms coming through on the
/// same stream and parsing each in turn.
class JsonRepeatDecoder extends Converter<String, dynamic> {
  final bool _strict;

  JsonRepeatDecoder({bool strict = false}) : _strict = strict;

  @override
  convert(String input) {
    json.encode(input);
  }

  @override
  Sink<String> startChunkedConversion(Sink sink) {
    return _JsonSplitterSink(sink, _strict);
  }
}

/// A [StringConversionSink] for handling chunks of JSON strings.
///
/// Gathers string slices into a [_buffer] until reaching the end of a JSON
/// form, whereupon it parses the form with [JSONDecoder] and adds the resulting
/// object to the output [_sink].
///
/// Note this splitter isn't too clever. It assumes that the incoming data is
/// already valid JSON, and proceeds without much ceremony to find the boundary
/// between valid JSON forms. For example, it will consider `["A"\]]` a valid
/// JSON form because even though it looks for a backslash, it doesn't assert
/// that the backslash is inside a string. Likewise `[1,2}` is considered a
/// valid form. Of course neither of those examples, nor any other malformed
/// JSON string, will survive the call to [JSONDecoder].
class _JsonSplitterSink extends StringConversionSinkBase {
  /// Output sink for transformed strings.
  final Sink _sink;

  final bool _strict;
  final StringBuffer _buffer = StringBuffer();

  int _stackDepth = 0;
  bool _quoted = false;
  bool _skipEscape = false;

  static const int _doubleQuote = 34;
  static const int _leftBrace = 123;
  static const int _rightBrace = 125;
  static const int _leftBracket = 91;
  static const int _rightBracket = 93;
  static const int _backslash = 92;

  _JsonSplitterSink(this._sink, this._strict);

  @override
  void addSlice(String str, int start, int end, bool isLast) {
    var sliceStart = start;
    for (var i = start; i < end; i++) {
      var char = str.codeUnitAt(i);
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
      var slice = str.substring(sliceStart, i + 1);
      _emit(slice);
      sliceStart = i + 1;
    }
    // If `str` not exhausted, stash tail in `_buffer` to be prepended to next
    // slice.
    if (sliceStart < end) {
      _buffer.write(str.substring(sliceStart, end));
    }
    if (isLast) {
      close();
    }
  }

  void _emit(String slice) {
    _buffer.write(slice);
    _sink.add(jsonDecode(_buffer.toString()));
    _buffer.clear();
  }

  @override
  void close() {
    if (_strict && _buffer.isNotEmpty) {
      _emit("");
    }
    _sink.close();
  }
}

/// A [Converter] that encodes multiple JSON objects to strings.
///
/// The Dart-provided [JsonEncoder] closes its underlying string after encoding
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
