import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:async/async.dart' hide StreamSplitter;
import 'package:typed_data/typed_buffers.dart';

import 'combiner.dart';
import 'splitter.dart';
import '../values/float.dart';

/// A [Converter] that decodes MessagePack bytes into native Dart objects.
///
/// Not quite a 100% faithful implementation of the [MessagePack
/// specification](https://github.com/msgpack/msgpack/blob/master/spec.md#array-format-family).
/// For the purposes of transit, a MessagePack `map` is parsed into a transit
/// 'map-as-array' value with the initial "^ " marker, preserving the key-value
/// pair order.
class MessagePackDecoder extends Splitter<List<int>, dynamic> {
  final Utf8Codec _codec = Utf8Codec();

  @override
  Stream split(stream) async* {
    final chunk = ChunkedStreamReader(stream);
    var b = await chunk.readBytes(1);
    while (b.isNotEmpty) {
      final u = b[0];
      yield await _decode(u, chunk);
      b = await chunk.readBytes(1);
    }
  }

  Future<dynamic> _decode(int u, ChunkedStreamReader<int> chunk) async {
    if (u <= 127) {
      return u;
    } else if ((u & 0xe0) == 0xe0) {
      return u - 256;
    } else if ((u & 0xe0) == 0xa0) {
      return await _readString(chunk, u & 0x1f);
    } else if ((u & 0xf0) == 0x80) {
      return await _readMap(chunk, u & 0xF);
    } else if ((u & 0xf0) == 0x90) {
      return await _readArray(chunk, u & 0xF);
    }
    switch (u) {
      case 0xc0:
        return null;
      case 0xc2:
        return false;
      case 0xc3:
        return true;
      case 0xcc:
        return await _readInt(chunk, 1, (bd) => bd.getUint8(0));
      case 0xcd:
        return await _readInt(chunk, 2, (bd) => bd.getUint16(0));
      case 0xce:
        return await _readInt(chunk, 4, (bd) => bd.getUint32(0));
      case 0xcf:
        return await _readInt(chunk, 8, (bd) => bd.getUint64(0));
      case 0xd0:
        return await _readInt(chunk, 1, (bd) => bd.getInt8(0));
      case 0xd1:
        return await _readInt(chunk, 2, (bd) => bd.getInt16(0));
      case 0xd2:
        return await _readInt(chunk, 4, (bd) => bd.getInt32(0));
      case 0xd3:
        return await _readInt(chunk, 8, (bd) => bd.getInt64(0));
      case 0xca:
        return await _readFloat(chunk);
      case 0xcb:
        return await _readDouble(chunk);
      case 0xd9:
        return await _readString(
            chunk, await _readInt(chunk, 1, (bd) => bd.getUint8(0)));
      case 0xda:
        return await _readString(
            chunk, await _readInt(chunk, 2, (bd) => bd.getUint16(0)));
      case 0xdb:
        return await _readString(
            chunk, await _readInt(chunk, 4, (bd) => bd.getUint32(0)));
      case 0xc4:
        return await _readBuffer(
            chunk, await _readInt(chunk, 1, (bd) => bd.getUint8(0)));
      case 0xc5:
        return await _readBuffer(
            chunk, await _readInt(chunk, 2, (bd) => bd.getUint16(0)));
      case 0xc6:
        return await _readBuffer(
            chunk, await _readInt(chunk, 4, (bd) => bd.getUint32(0)));
      case 0xdc:
        return await _readArray(
            chunk, await _readInt(chunk, 2, (bd) => bd.getUint16(0)));
      case 0xdd:
        return await _readArray(
            chunk, await _readInt(chunk, 4, (bd) => bd.getUint32(0)));
      case 0xde:
        return await _readMap(
            chunk, await _readInt(chunk, 2, (bd) => bd.getUint16(0)));
      case 0xdf:
        return await _readMap(
            chunk, await _readInt(chunk, 4, (bd) => bd.getUint32(0)));
    }
  }

  Future<int> _readInt(ChunkedStreamReader<int> chunk, int size,
      int Function(ByteData) getter) async {
    final b = await _expectBytes(chunk, size);
    return getter(ByteData.sublistView(b));
  }

  Future<Float> _readFloat(ChunkedStreamReader<int> chunk) async {
    final b = await _expectBytes(chunk, 4);
    return Float(ByteData.sublistView(b).getFloat32(0));
  }

  Future<double> _readDouble(ChunkedStreamReader<int> chunk) async {
    final b = await _expectBytes(chunk, 8);
    return ByteData.sublistView(b).getFloat64(0);
  }

  Future<Uint8List> _readBuffer(ChunkedStreamReader<int> chunk, int len) async {
    final b = await _expectBytes(chunk, len);
    // Do we need to copy the bytes here?
    return b;
  }

  Future<String> _readString(ChunkedStreamReader<int> chunk, int len) async {
    final list = await _readBuffer(chunk, len);
    return _codec.decode(list);
  }

  // Parses a "map", but since the only map we should encounter is a transit
  // iterable map, with stringable keys, we return a transit map-as-array with
  // the initial '^ ' marker.
  Future<List> _readMap(ChunkedStreamReader<int> chunk, int len) async {
    final m = [];
    m.add('^ ');
    for (var i = 0; i < len; i++) {
      final uKey = await _expectBytes(chunk, 1);
      final key = await _decode(uKey[0], chunk);
      m.add(key);
      final uVal = await _expectBytes(chunk, 1);
      final val = await _decode(uVal[0], chunk);
      m.add(val);
    }
    return m;
  }

  Future<List> _readArray(ChunkedStreamReader<int> chunk, int len) async {
    final l = List<dynamic>.filled(len, null, growable: false);
    for (var i = 0; i < len; i++) {
      final u = await _expectBytes(chunk, 1);
      l[i] = await _decode(u[0], chunk);
    }
    return l;
  }

  Future<Uint8List> _expectBytes(
      ChunkedStreamReader<int> chunk, int len) async {
    final b = await chunk.readBytes(len);
    if (b.length != len) {
      throw Exception('Upstream closed');
    }
    return b;
  }
}

/// A [Converter] from native Dart objects to MessagePack byte representation.
class MessagePackEncoder extends Combiner<dynamic, Uint8List> {
  final Utf8Codec _codec = Utf8Codec();
  final Uint8Buffer _buffer = Uint8Buffer();

  @override
  encode(input) {
    _buffer.clear();
    _write(input);
    return _buffer.buffer.asUint8List(0, _buffer.lengthInBytes);
  }

  void _write(dynamic obj) {
    if (null == obj) {
      _writeUint8(0xc0);
    } else if (obj is bool) {
      _writeUint8(obj ? 0xc3 : 0xc2);
    } else if (obj is int) {
      obj >= 0 ? _writePositiveInt(obj) : _writeNegativeInt(obj);
    } else if (obj is Float) {
      _writeDouble32(obj.value);
    } else if (obj is double) {
      _writeDouble64(obj);
    } else if (obj is String) {
      _writeString(obj);
    } else if (obj is Uint8List) {
      _writeBinary(obj);
    } else if (obj is ByteData) {
      _writeBinary(
          obj.buffer.asUint8List(obj.offsetInBytes, obj.lengthInBytes));
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
      _writeUint8(i);
    } else if (i <= 0xff) {
      _writeUint8(0xcc);
      _writeUint8(i);
    } else if (i <= 0xffff) {
      _writeUint8(0xcd);
      _writeUint16(i);
    } else if (i <= 0xffffffff) {
      _writeUint8(0xce);
      _writeUint32(i);
    } else {
      _writeUint8(0xcf);
      _writeUint64(i);
    }
  }

  void _writeNegativeInt(int i) {
    if (i >= -32) {
      _writeInt8(i);
    } else if (i >= -128) {
      _writeUint8(0xd0);
      _writeInt8(i);
    } else if (i >= -32768) {
      _writeUint8(0xd1);
      _writeInt16(i);
    } else if (i >= -2147483648) {
      _writeUint8(0xd2);
      _writeInt32(i);
    } else {
      _writeUint8(0xd3);
      _writeInt64(i);
    }
  }

  ByteData _pad(int size) {
    final len = _buffer.lengthInBytes;
    _buffer.addAll(Uint8List(size));
    final view = _buffer.buffer.asUint8List(len);
    return ByteData.sublistView(view);
  }

  void _writeUint8(int i) {
    _pad(1).setUint8(0, i);
  }

  void _writeUint16(int i) {
    _pad(2).setUint16(0, i);
  }

  void _writeUint32(int i) {
    _pad(4).setUint32(0, i);
  }

  void _writeUint64(int i) {
    _pad(8).setUint64(0, i);
  }

  void _writeInt8(int i) {
    _pad(1).setInt8(0, i);
  }

  void _writeInt16(int i) {
    _pad(2).setInt16(0, i);
  }

  void _writeInt32(int i) {
    _pad(4).setInt32(0, i);
  }

  void _writeInt64(int i) {
    _pad(8).setInt64(0, i);
  }

  void _writeDouble32(d) {
    _writeUint8(0xca);
    _pad(4).setFloat32(0, d);
  }

  void _writeDouble64(d) {
    _writeUint8(0xcb);
    _pad(8).setFloat64(0, d);
  }

  void _writeString(String s) {
    final encoded = _codec.encode(s);
    final len = encoded.length;
    if (len <= 31) {
      _writeUint8(0xa0 | len);
    } else if (len <= 0xff) {
      _writeUint8(0xd9);
      _writeUint8(len);
    } else if (len <= 0xffff) {
      _writeUint8(0xda);
      _writeUint16(len);
    } else if (len <= 0xffffffff) {
      _writeUint8(0xdb);
      _writeUint32(len);
    } else {
      throw Exception('String too long for msgpack');
    }
    _writeBytes(Uint8List.fromList(encoded));
  }

  void _writeBinary(Uint8List b) {
    final len = b.length;
    if (len <= 0xff) {
      _writeUint8(0xc4);
      _writeUint8(len);
    } else if (len <= 0xffff) {
      _writeUint8(0xc5);
      _writeUint16(len);
    } else if (len <= 0xffffffff) {
      _writeUint8(0xc6);
      _writeUint32(len);
    } else {
      throw Exception('String too long for msgpack');
    }
    _writeBytes(b);
  }

  void _writeBytes(Uint8List b) {
    _buffer.addAll(b);
  }

  void _writeIterable(Iterable l) {
    final len = l.length;
    if (len <= 15) {
      _writeUint8(0x90 | len);
    } else if (len <= 0xffff) {
      _writeUint8(0xdc);
      _writeUint16(len);
    } else if (len <= 0xffffffff) {
      _writeUint8(0xdd);
      _writeUint32(len);
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
      _writeUint8(0x80 | len);
    } else if (len <= 0xffff) {
      _writeUint8(0xde);
      _writeUint16(len);
    } else if (len <= 0xffffffff) {
      _writeUint8(0xdf);
      _writeUint32(len);
    } else {
      throw Exception('Map too long for msgpack');
    }
    for (final i in m.entries) {
      _write(i.key);
      _write(i.value);
    }
  }
}
