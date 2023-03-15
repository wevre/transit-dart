// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';

// Character constants.

const int _doubleQuote = 34;
const int _leftBrace = 123;
const int _rightBrace = 125;
const int _leftBracket = 91;
const int _rightBracket = 93;
const int _backslash = 92;

class JsonBuilder {
  int stackDepth = 0;
  bool quoted = false;
  bool skipEscape = false;

  final void Function(String data) _sinkAdder;

  JsonBuilder(this._sinkAdder);

  int addData(String data, int start, int end) {
    var sliceStart = start;
    for (var i = start; i < end; i++) {
      var char = data.codeUnitAt(i);
      // Initialize if this is the first char we've seen.
      if (0 == stackDepth) {
        assert(_leftBrace == char || _leftBracket == char);
        stackDepth++;
        continue;
      }
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
          if (!quoted) stackDepth++;
          continue;
        case _rightBrace:
        case _rightBracket:
          if (--stackDepth > 0) {
            continue;
          }
          break;
        case _backslash:
          skipEscape = true;
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
  const JsonSplitter();

  List<String> convert(String data) {
    var objs = <String>[];
    var builder = JsonBuilder((data) {
      objs.add(data);
    });
    var end = data.length;
    var sliceStart = builder.addData(data, 0, end);
    if (sliceStart < end) {
      objs.add(data.substring(sliceStart, end));
    }
    return objs;
  }

  StringConversionSink startChunkedConversion(Sink<String> sink) {
    return _JsonSplitterSink(
        sink is StringConversionSink ? sink : StringConversionSink.from(sink));
  }

  @override
  Stream<String> bind(Stream<String> stream) {
    return Stream<String>.eventTransformed(
        stream, (EventSink<String> sink) => _JsonSplitterEventSink(sink));
  }
}

class _JsonSplitterSink extends StringConversionSinkBase {
  final StringConversionSink _sink;
  final StringBuffer _carry = StringBuffer();

  late final JsonBuilder builder;

  _JsonSplitterSink(this._sink) {
    builder = JsonBuilder((data) {
      _sink.add(_useCarry(data));
    });
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
    if (_carry.isNotEmpty) {
      _sink.add(_useCarry(""));
    }
    _sink.close();
  }

  void _addData(String data, int start, int end, bool isLast) {
    var sliceStart = builder.addData(data, start, end);
    if (sliceStart < end) {
      var endSlice = data.substring(sliceStart, end);
      if (isLast) {
        // Emit last line instead of carrying it over to the
        // immediately following `close` call.
        _sink.add(_useCarry(endSlice));
        return;
      }
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

  _JsonSplitterEventSink(EventSink<String> eventSink)
      : _eventSink = eventSink,
        super(StringConversionSink.from(eventSink));

  @override
  void addError(Object o, [StackTrace? stackTrace]) {
    _eventSink.addError(o, stackTrace);
  }
}
