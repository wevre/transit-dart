import 'dart:convert';

/// A [Converter] that encodes multiple objects to a stream.
///
/// This is the counterpart to [Splitter] and like that class and its [split]
/// method, the crucial piece here is the [encode] method, and everything
/// else is boilerplate.
abstract class Combiner<S, T> extends Converter<S, T> {
  /// Subclasses override to transform an object before it is added to the
  /// output stream.
  T encode(S input);

  @override
  convert(input) => encode(input);

  @override
  startChunkedConversion(sink) => _CombinerSink(sink, encode);
}

class _CombinerSink<S, T> extends ChunkedConversionSink<S> {
  final Sink<T> _sink;
  final T Function(S chunk) _serialize;

  _CombinerSink(this._sink, this._serialize);

  @override
  void add(chunk) {
    _sink.add(_serialize(chunk));
  }

  @override
  void close() {
    _sink.close();
  }
}
