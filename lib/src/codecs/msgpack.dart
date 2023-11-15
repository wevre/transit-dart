import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:typed_data/typed_buffers.dart';

import 'combiner.dart';
// import 'splitter.dart';

/// A [Converter] that decodes MessagePack bytes into native Dart objects.
///
/// ONLY THE SUBSET OF MSGPACK REQUIRED BY TRANSIT IS SUPPORTED
///
/// Not quite a 100% faithful implementation of the [MessagePack
/// specification](https://github.com/msgpack/msgpack/blob/master/spec.md#array-format-family).
/// For the purposes of transit, a MessagePack `map` is parsed into a transit
/// 'map-as-array' value with the initial "^ " marker, preserving the key-value
/// pair order.

class BytesReader {
  ByteData _data;
  int _pos = 0;

  BytesReader(ByteData this._data);

  int readUint8() {
    int p = _pos + 1;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getUint8(_pos);
    _pos = p;
    return r;
  }

  int readUint16() {
    int p = _pos + 2;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getUint16(_pos);
    _pos = p;
    return r;
  }

  int readUint32() {
    int p = _pos + 4;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getUint32(_pos);
    _pos = p;
    return r;
  }

  int readUint64() {
    int p = _pos + 8;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getUint64(_pos);
    _pos = p;
    return r;
  }

  int readInt8() {
    int p = _pos + 1;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getInt8(_pos);
    _pos = p;
    return r;
  }

  int readInt16() {
    int p = _pos + 2;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getInt16(_pos);
    _pos = p;
    return r;
  }

  int readInt32() {
    int p = _pos + 4;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getInt32(_pos);
    _pos = p;
    return r;
  }

  int readInt64() {
    int p = _pos + 8;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getInt64(_pos);
    _pos = p;
    return r;
  }

  double readFloat32() {
    int p = _pos + 4;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getFloat32(_pos);
    _pos = p;
    return r;
  }

  double readFloat64() {
    int p = _pos + 8;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.getFloat64(_pos);
    _pos = p;
    return r;
  }

  Uint8List readBytes(int length) {
    int p = _pos + length;
    if (_data.lengthInBytes < p) throw this;
    final r = _data.buffer.asUint8List(_data.offsetInBytes + _pos, length);
    _pos = p;
    return r;
  }
}

class BytesWriter {
  final _buffer = BytesBuilder();
  final _scratch = ByteData(8);

  void clear() => _buffer.clear();
  Uint8List takeBytes() => _buffer.takeBytes();

  void writeUint8(int i) {
    _buffer.addByte(i);
  }

  void writeUint16(int i) {
    _scratch.setUint16(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
  }

  void writeUint32(int i) {
    _scratch.setUint32(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
  }

  void writeUint64(int i) {
    _scratch.setUint64(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
    _buffer.addByte(_scratch.getUint8(4));
    _buffer.addByte(_scratch.getUint8(5));
    _buffer.addByte(_scratch.getUint8(6));
    _buffer.addByte(_scratch.getUint8(7));
  }

  void writeInt8(int i) {
    _scratch.setInt8(0, i);
    _buffer.addByte(_scratch.getUint8(0));
  }

  void writeInt16(int i) {
    _scratch.setInt16(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
  }

  void writeInt32(int i) {
    _scratch.setInt32(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
  }

  void writeInt64(int i) {
    _scratch.setInt64(0, i);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
    _buffer.addByte(_scratch.getUint8(4));
    _buffer.addByte(_scratch.getUint8(5));
    _buffer.addByte(_scratch.getUint8(6));
    _buffer.addByte(_scratch.getUint8(7));
  }

  void writeFloat32(double d) {
    _scratch.setFloat32(0, d);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
  }

  void writeFloat64(double d) {
    _scratch.setFloat64(0, d);
    _buffer.addByte(_scratch.getUint8(0));
    _buffer.addByte(_scratch.getUint8(1));
    _buffer.addByte(_scratch.getUint8(2));
    _buffer.addByte(_scratch.getUint8(3));
    _buffer.addByte(_scratch.getUint8(4));
    _buffer.addByte(_scratch.getUint8(5));
    _buffer.addByte(_scratch.getUint8(6));
    _buffer.addByte(_scratch.getUint8(7));
  }

  void writeBytes(List<int> bytes) => _buffer.add(bytes);
}

class Continuation {
  dynamic Function(BytesReader) _resume;
  Continuation(this._resume);
}

final Utf8Codec _codec = Utf8Codec(allowMalformed: true);

class MessagePackDecodingSink implements Sink<Uint8List> {
  Sink<dynamic> _sink;
  dynamic Function(BytesReader) _reader;
  BytesBuilder _builder = BytesBuilder(copy: false);

  MessagePackDecodingSink(this._sink) : _reader = read;

  @override
  void add(Uint8List chunk) {
    _builder.add(chunk);
    final bytesList = _builder.takeBytes();
    final bytesReader = BytesReader(
        bytesList.buffer.asByteData(bytesList.offsetInBytes, bytesList.length));
    try {
      while (bytesReader._pos < bytesList.length) {
        // parse until input is exhausted
        _sink.add(_reader(bytesReader));
        _reader = read;
      }
    } on Continuation catch (e) {
      _reader = e._resume;
      _builder.add(bytesList.sublist(bytesReader._pos));
    }
  }

  @override
  void close() {
    // _reader is identical to _read only iff the while loop properly stopped (or never started)
    // thus if they differ it means some message is actually being partially parsed.
    if (!identical(_reader, read))
      throw Exception("EOF reached while parsing message.");
    _sink.close();
  }
}

class MessagePackDecoder extends Converter<Uint8List, dynamic> {
  @override
  convert(Uint8List input) {
    try {
      return read(BytesReader(
          input.buffer.asByteData(input.offsetInBytes, input.length)));
    } on Continuation catch (e) {
      throw Exception("EOF reached while parsing message.");
    }
  }

  @override
  Sink<Uint8List> startChunkedConversion(Sink<dynamic> sink) {
    return MessagePackDecodingSink(sink);
  }
}

_mapContinuation(dynamic resume(BytesReader bytes), Map<dynamic, dynamic> m,
    int n, dynamic k) {
  return Continuation((BytesReader bytes) {
    try {
      if (identical(k, m)) {
        // suspended whie reading k
        k = resume(bytes);
        m[k] = read(bytes);
      } else {
        // suspended while reading v
        m[k] = resume(bytes);
      }
    } on Continuation catch (e) {
      throw _mapContinuation(e._resume, m, n, k);
    }
    return _readMap(bytes, n - 1, m);
  });
}

Map _readMap(BytesReader bytes, int n, Map<dynamic, dynamic> m) {
  dynamic k = m; // sentinel meaning k not read
  try {
    for (; n > 0; n--) {
      k = read(bytes);
      m[k] = read(bytes);
      k = m;
    }
    return m;
  } on Continuation catch (e) {
    throw _mapContinuation(e._resume, m, n, k);
  }
}

Map readMap(BytesReader bytes, int n) {
  return _readMap(bytes, n, <dynamic, dynamic>{});
}

_arrayContinuation(
    dynamic resume(BytesReader bytes), List<dynamic> a, int i, int n) {
  return Continuation((BytesReader bytes) {
    try {
      a[i] = resume(bytes);
    } on Continuation catch (e) {
      throw _arrayContinuation(e._resume, a, i, n);
    }
    return _readArray(bytes, n, a, i + 1);
  });
}

List _readArray(BytesReader bytes, int n, List<dynamic> a, int i) {
  try {
    for (; i < n; i++) a[i] = read(bytes);
    return a;
  } on Continuation catch (e) {
    throw _arrayContinuation(e._resume, a, i, n);
  }
}

List readArray(BytesReader bytes, int n) {
  return _readArray(bytes, n, List<dynamic>.filled(n, null), 0);
}

String readString(BytesReader bytes, int n) {
  late final data;
  try {
    data = bytes.readBytes(n);
  } catch (e) {
    if (!identical(e, bytes)) rethrow;
    throw Continuation((BytesReader bytes) {
      return readString(bytes, n);
    });
  }
  return _codec.decode(data);
}

dynamic _read(BytesReader bytes, int u) {
  try {
    if (u <= 127) {
      return u;
    } else if ((u & 0xe0) == 0xe0) {
      return u - 256;
    } else if ((u & 0xe0) == 0xa0) {
      return readString(bytes, u & 0x1f);
    } else if ((u & 0xf0) == 0x80) {
      return readMap(bytes, u & 0xf);
    } else if ((u & 0xf0) == 0x90) {
      return readArray(bytes, u & 0xf);
    }
    switch (u) {
      case 0xc0:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;
      case 0xcc:
        return bytes.readUint8();
      case 0xcd:
        return bytes.readUint16();
      case 0xce:
        return bytes.readUint32();
      case 0xcf:
        return bytes.readUint64();
      case 0xd0:
        return bytes.readInt8();
      case 0xd1:
        return bytes.readInt16();
      case 0xd2:
        return bytes.readInt32();
      case 0xd3:
        return bytes.readInt64();
      case 0xca:
        return bytes.readFloat32();
      case 0xcb:
        return bytes.readFloat64();
    }
    switch (u) {
      case 0xd9:
        return readString(bytes, bytes.readUint8());
      case 0xda:
        return readString(bytes, bytes.readUint16());
      case 0xdb:
        return readString(bytes, bytes.readUint32());
      case 0xdc:
        return readArray(bytes, bytes.readUint16());
      case 0xdd:
        return readArray(bytes, bytes.readUint32());
      case 0xde:
        return readMap(bytes, bytes.readUint16());
      case 0xdf:
        return readMap(bytes, bytes.readUint32());
    }
  } on Continuation catch (e) {
    rethrow;
  } catch (e) {
    if (!identical(e, bytes)) rethrow;
    throw Continuation((bytes) => _read(bytes, u));
  }
  throw Exception("Unexpected byte ${u} at offset ${bytes._pos}");
}

dynamic read(BytesReader bytes) {
  int u = 0;
  try {
    u = bytes.readUint8();
  } catch (e) {
    if (!identical(e, bytes)) rethrow;
    throw Continuation(read);
  }
  return _read(bytes, u);
}

/// A [Converter] from native Dart objects to MessagePack byte representation.
class MessagePackEncoder extends StreamMappingConverter<dynamic, Uint8List> {
  final _buffer = BytesWriter();

  @override
  convert(input) {
    _buffer.clear();
    _write(input);
    return _buffer.takeBytes();
  }

  void _write(dynamic obj) {
    if (null == obj) {
      _buffer.writeUint8(0xc0);
    } else if (obj is bool) {
      _buffer.writeUint8(obj ? 0xc3 : 0xc2);
    } else if (obj is int) {
      obj >= 0 ? _writePositiveInt(obj) : _writeNegativeInt(obj);
    } else if (obj is double) {
      _buffer.writeUint8(0xcb);
      _buffer.writeFloat64(obj);
    } else if (obj is String) {
      _writeString(obj);
    } else if (obj is Iterable) {
      _writeIterable(obj);
    } else if (obj is Map) {
      _writeMap(obj);
    } else {
      throw Exception('No writer for object `$obj` of type ${obj.runtimeType}');
    }
  }

  void _writePositiveInt(int i) {
    if (i <= 127) {
      _buffer.writeUint8(i);
    } else if (i <= 0xff) {
      _buffer.writeUint8(0xcc);
      _buffer.writeUint8(i);
    } else if (i <= 0xffff) {
      _buffer.writeUint8(0xcd);
      _buffer.writeUint16(i);
    } else if (i <= 0xffffffff) {
      _buffer.writeUint8(0xce);
      _buffer.writeUint32(i);
    } else {
      _buffer.writeUint8(0xcf);
      _buffer.writeUint64(i);
    }
  }

  void _writeNegativeInt(int i) {
    if (i >= -32) {
      _buffer.writeInt8(i);
    } else if (i >= -128) {
      _buffer.writeUint8(0xd0);
      _buffer.writeInt8(i);
    } else if (i >= -32768) {
      _buffer.writeUint8(0xd1);
      _buffer.writeInt16(i);
    } else if (i >= -2147483648) {
      _buffer.writeUint8(0xd2);
      _buffer.writeInt32(i);
    } else {
      _buffer.writeUint8(0xd3);
      _buffer.writeInt64(i);
    }
  }

  void _writeString(String s) {
    final encoded = _codec.encode(s);
    final len = encoded.length;
    if (len <= 31) {
      _buffer.writeUint8(0xa0 | len);
    } else if (len <= 0xff) {
      _buffer.writeUint8(0xd9);
      _buffer.writeUint8(len);
    } else if (len <= 0xffff) {
      _buffer.writeUint8(0xda);
      _buffer.writeUint16(len);
    } else if (len <= 0xffffffff) {
      _buffer.writeUint8(0xdb);
      _buffer.writeUint32(len);
    } else {
      throw Exception('String too long for msgpack');
    }
    _buffer.writeBytes(encoded);
  }

  void _writeIterable(Iterable l) {
    final len = l.length;
    if (len <= 15) {
      _buffer.writeUint8(0x90 | len);
    } else if (len <= 0xffff) {
      _buffer.writeUint8(0xdc);
      _buffer.writeUint16(len);
    } else if (len <= 0xffffffff) {
      _buffer.writeUint8(0xdd);
      _buffer.writeUint32(len);
    } else {
      throw Exception('Array too long for msgpack');
    }
    for (final i in l) {
      _write(i);
    }
  }

  void _writeMap(Map m) {
    final len = m.length;
    if (len <= 15) {
      _buffer.writeUint8(0x80 | len);
    } else if (len <= 0xffff) {
      _buffer.writeUint8(0xde);
      _buffer.writeUint16(len);
    } else if (len <= 0xffffffff) {
      _buffer.writeUint8(0xdf);
      _buffer.writeUint32(len);
    } else {
      throw Exception('Map too long for msgpack');
    }
    for (final i in m.entries) {
      _write(i.key);
      _write(i.value);
    }
  }
}
