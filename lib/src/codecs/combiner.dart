import 'dart:convert';

/// A [Converter] which when used to transform a Stream will transform each item with convert.
abstract class StreamMappingConverter<S, T> extends Converter<S, T> {
  StreamMappingConverter();

  factory StreamMappingConverter.from(T f(S s)) {
    return StreamFnMappingConverter(f);
  }

  @override
  startChunkedConversion(sink) => _MappingSink(sink, convert);
}

class StreamFnMappingConverter<S, T> extends StreamMappingConverter<S, T> {
  final T Function(S) _f;

  StreamFnMappingConverter(this._f);

  @override
  convert(x) => _f(x);
}

class _MappingSink<S, T> implements Sink<S> {
  final Sink<T> _sink;
  final T Function(S) _f;

  _MappingSink(this._sink, this._f);

  @override
  void add(x) {
    _sink.add(_f(x));
  }

  @override
  void close() {
    _sink.close();
  }
}
