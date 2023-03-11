//

import 'dart:convert';

const _digits = 44;
const _base = 48;
const _prefix = '^';
const _maxEntries = _digits * _digits;

String _cacheEncode(int index) {
  int h = index ~/ _digits + _base;
  int l = index % _digits + _base;
  if (h == _base) {
    return "$_prefix${String.fromCharCode(l)}";
  } else {
    return "$_prefix${String.fromCharCode(h)}${String.fromCharCode(l)}";
  }
}

int _cacheDecode(String s) {
  if (2 == s.length) {
    return (s.codeUnitAt(1) - _base);
  } else {
    return (s.codeUnitAt(1) - _base) * _digits + (s.codeUnitAt(2) - _base);
  }
}

class CacheEncoder extends Converter<String, String> {
  final Map<String, String> _cache = {};

  void _reset() {
    _cache.clear();
  }

  CacheEncoder() {
    _reset();
  }

  @override
  String convert(String input, {bool asMapKey = false}) {
    if (_cache.containsKey(input)) {
      return _cache[input]!;
    }
    if (input.length > 3) {
      if (_cache.length == _maxEntries) {
        _reset();
      }
      _cache[input] = _cacheEncode(_cache.length);
    }
    return input;
  }
}

class CacheDecoder extends Converter<String, String> {
  final List<String> _cache = [];

  void _reset() {
    _cache.clear();
  }

  CacheDecoder() {
    _reset();
  }

  @override
  String convert(String input) {
    if (_prefix == input[0] && input != '^ ') {
      return _cache[_cacheDecode(input)];
    }
    if (input.length > 3) {
      if (_cache.length == _maxEntries) {
        _reset();
      }
      _cache.add(input);
    }
    return input;
  }
}
