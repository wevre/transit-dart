import 'dart:async';
import 'dart:convert';

/// Divides and transforms a stream.
///
/// This Converter abstracts the commonality between the JsonRepeat coders and
/// the MessagePack coders, both of which split a stream into slices
/// (representing a single JSON form or a single MessagePack object) and then
/// parse each slice into a native Dart object. The crucial piece for processing
/// the stream is provided by subclasses overriding the [split] function, and
/// the rest is just boilerplate, which this class deals with (along with some
/// supporting classes).
abstract class Splitter<S, T> extends Converter<S, T> {
  /// Converts a single object from the stream.
  ///
  /// If there are multiple encoded objects to convert, use the stream API's
  /// instaed of this method.
  @override
  convert(S input) async {
    return Stream.value(input)
        .transform(_SplitterStreamTransformer(split))
        .first;
  }

  @override
  Sink<S> startChunkedConversion(Sink sink) {
    return _SplitterStreamSink<S>(sink, _SplitterStreamTransformer(split));
  }

  /// Splits an input stream and transforms each 'slice'.
  Stream split(Stream<S> stream);
}

/// A [StreamTransformer] that splits a stream using the provided [_binder]
/// callback.
class _SplitterStreamTransformer<S> extends StreamTransformerBase<S, dynamic> {
  final Stream Function(Stream<S>) _binder;

  _SplitterStreamTransformer(this._binder);

  @override
  bind(stream) {
    return _binder(stream);
  }
}

/// A [Sink] used in [Splitter]'s chunked conversion that transforms incoming
/// objects en route to adding them to the output sink.
class _SplitterStreamSink<S> extends Sink<S> {
  final StreamController<S> _controller;

  _SplitterStreamSink(Sink sink, _SplitterStreamTransformer<S> transformer)
      : _controller = StreamController() {
    // The provided `transformer` is applied to the controller's `stream`, and
    // each transformed object is added to the output `sink`.
    _controller.stream.transform(transformer).listen((event) {
      sink.add(event);
    });
  }

  /// Adds incoming objects (chunks of the original stream) to the controller
  /// via its [sink].
  @override
  void add(S chunk) {
    _controller.sink.add(chunk);
  }

  @override
  void close() {
    _controller.sink.close();
  }
}
