import 'dart:async';
import 'dart:convert';

/// This splitter isn't too clever. It assumes that the incoming data is already
/// valid JSON, and proceeds without too much ceremony to find the boundary
/// between valid JSON forms. For example, it will consider `["A"\]]` a valid
/// JSON form because even though it looks for the backslash, it doesn't assert
/// that backslash is inside a string.

// Character constants.

const int _doubleQuote = 34;
const int _leftBrace = 123;
const int _rightBrace = 125;
const int _leftBracket = 91;
const int _rightBracket = 93;
const int _backslash = 92;

// I split this out into a separate class because I thought it would be needed
// by different interfaces. But if I get rid of convert (which looked like an
// override, but it wasn't really) then I'm doing the char testing in only one
// place.
class JsonBuilder {
  final bool _strict;
  int _stackDepth = 0;
  bool _quoted = false;
  bool _skipEscape = false;

  final void Function(String data) _sinkAdder;

  final void Function()? _carryReset;

  JsonBuilder(this._sinkAdder, this._carryReset, this._strict);

  int addData(String data, int start, int end) {
    var sliceStart = start;
    for (var i = start; i < end; i++) {
      var char = data.codeUnitAt(i);
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
            if (null != _carryReset) {
              _carryReset!();
            }
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
      // We completed an array or object.
      var slice = data.substring(sliceStart, i + 1);
      _sinkAdder(slice);
      sliceStart = i + 1;
    }
    // We ran through the data.
    return sliceStart;
  }
}

class JsonSplitter extends StreamTransformerBase<String, dynamic> {
  final bool _strict;

  const JsonSplitter({strict = false}) : _strict = strict;

  @override
  Stream<dynamic> bind(Stream<String> stream) {
    return Stream<dynamic>.eventTransformed(stream,
        (EventSink<dynamic> sink) => _JsonSplitterEventSink(sink, _strict));
  }
}

// why split this into two? It was to support the `startChunkedConversion`
// method, but that wasn't even a real override. Not sure why it existed on the
// LineSplitter class, but we don't need it for this class.
class _JsonSplitterSink extends StringConversionSinkBase {
  final Sink<dynamic> _sink;
  final bool _strict;
  final StringBuffer _carry = StringBuffer();

  late final JsonBuilder builder;

  _JsonSplitterSink(this._sink, this._strict) {
    builder = JsonBuilder((data) {
      _sink.add(_useCarry(data));
    }, () {
      _carry.clear();
    }, _strict);
  }

  @override
  void addSlice(String chunk, int start, int end, bool isLast) {
    end = RangeError.checkValidRange(start, end, chunk.length);
    // If the chunk is empty, it's probably because it's the last one.
    // Handle that here, so we know the range is non-empty below.
    if (start < end) {
      _addData(chunk, start, end);
    }
    if (isLast) close();
  }

  @override
  void close() {
    if (_strict && _carry.isNotEmpty) {
      _sink.add(_useCarry(""));
    }
    _sink.close();
  }

  void _addData(String data, int start, int end) {
    var sliceStart = builder.addData(data, start, end);
    if (sliceStart < end) {
      var endSlice = data.substring(sliceStart, end);
      _addCarry(endSlice);
    }
  }

  /// Adds [newCarry] to existing carry-over.
  ///
  /// Happens when a line is spread over more than one chunk.
  void _addCarry(String newCarry) {
    _carry.write(newCarry);
  }

  /// Consumes and combines existing carry-over with continuation string.
  dynamic _useCarry(String continuation) {
    _carry.write(continuation);
    var result = json.decode(_carry.toString());
    _carry.clear();
    return result;
  }
}

class _JsonSplitterEventSink extends _JsonSplitterSink
    implements EventSink<String> {
  final EventSink<dynamic> _eventSink;

  _JsonSplitterEventSink(EventSink<dynamic> eventSink, bool strict)
      : _eventSink = eventSink,
        super(eventSink, strict);

  @override
  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
