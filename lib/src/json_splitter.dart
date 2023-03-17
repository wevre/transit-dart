// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/// A [StreamTransformer] that splits a [String] into individual lines.
///
/// A line is terminated by either:
/// * a CR, carriage return: U+000D ('\r')
/// * a LF, line feed (Unix line break): U+000A ('\n') or
/// * a CR+LF sequence (DOS/Windows line break), and
/// * a final non-empty line can be ended by the end of the input.
///
/// The resulting lines do not contain the line terminators.
///
/// Example:
/// ```dart
/// const splitter = JsonSplitter();
/// const sampleText =
///     'Dart is: \r an object-oriented \n class-based \n garbage-collected '
///     '\r\n language with C-style syntax \r\n';
///
/// final sampleTextLines = splitter.convert(sampleText);
/// for (var i = 0; i < sampleTextLines.length; i++) {
///   print('$i: ${sampleTextLines[i]}');
/// }
/// // 0: Dart is:
/// // 1:  an object-oriented
/// // 2:  class-based
/// // 3:  garbage-collected
/// // 4:  language with C-style syntax
/// ```
class JsonSplitter extends StreamTransformerBase<String, String> {
  final bool _strict;

  const JsonSplitter({strict = false}) : _strict = strict;

  List<String> convert(String data) {
    var objs = <String>[];
    var builder = JsonBuilder((data) {
      objs.add(data);
    }, null, _strict);
    var end = data.length;
    var sliceStart = builder.addData(data, 0, end);
    if (sliceStart < end && _strict) {
      objs.add(data.substring(sliceStart, end));
    }
    return objs;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    return _JsonSplitterSink(
        sink is StringConversionSink ? sink : StringConversionSink.from(sink),
        _strict);
  }

  @override
  Stream<String> bind(Stream<String> stream) {
    return Stream<String>.eventTransformed(stream,
        (EventSink<String> sink) => _JsonSplitterEventSink(sink, _strict));
  }
}

class _JsonSplitterSink extends StringConversionSinkBase {
  final StringConversionSink _sink;
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
      _addData(chunk, start, end, isLast);
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

  void _addData(String data, int start, int end, bool isLast) {
    var sliceStart = builder.addData(data, start, end);
    if (sliceStart < end) {
      var endSlice = data.substring(sliceStart, end);
      // if (isLast) {
      //   // Emit last line instead of carrying it over to the
      //   // immediately following `close` call.
      //   _sink.add(_useCarry(endSlice));
      //   return;
      // }
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
  String _useCarry(String continuation) {
    _carry.write(continuation);
    var result = _carry.toString();
    _carry.clear();
    return result;
  }
}

class _JsonSplitterEventSink extends _JsonSplitterSink
    implements EventSink<String> {
  final EventSink<String> _eventSink;

  _JsonSplitterEventSink(EventSink<String> eventSink, bool strict)
      : _eventSink = eventSink,
        super(StringConversionSink.from(eventSink), strict);

  @override
  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
