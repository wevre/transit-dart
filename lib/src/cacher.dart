//

import 'dart:convert';

import 'constants.dart';
import 'parser.dart';

const _digits = 44;
const _base = 48;
const _prefix = SUB;
const _maxEntries = _digits * _digits;

String _cacheEncode(int index) {
  int h = index ~/ _digits + _base;
  int l = index % _digits + _base;
  if (h == _base) {
    return '$_prefix${String.fromCharCode(l)}';
  } else {
    return '$_prefix${String.fromCharCode(h)}${String.fromCharCode(l)}';
  }
}

int _cacheDecode(String s) {
  if (2 == s.length) {
    return (s.codeUnitAt(1) - _base);
  } else {
    return (s.codeUnitAt(1) - _base) * _digits + (s.codeUnitAt(2) - _base);
  }
}

bool _isCacheable(String s, bool asMapKey) {
  return (s.length >= 4) &&
      (asMapKey ||
          (ESC == s[0] && (':' == s[1] || '\$' == s[1] || TAG == s[1])));
}

class CacheEncoder extends Converter<String, String> {
  final Map<String, String> _cache = {};

  void _reset() {
    _cache.clear();
  }

  CacheEncoder() {
    _reset();
  }

  bool isCacheable(String s, bool asMapKey) {
    return (s.length >= 4) &&
        (asMapKey ||
            (ESC == s[0] && (':' == s[1] || '\$' == s[1] || TAG == s[1])));
  }

  getCache() => _cache;

  @override
  String convert(String input, {bool asMapKey = false}) {
    if (_isCacheable(input, asMapKey)) {
      if (_cache.containsKey(input)) {
        return _cache[input]!;
      } else {
        if (_cache.length == _maxEntries) {
          _reset();
        }
        _cache[input] = _cacheEncode(_cache.length);
      }
    }
    return input;
  }
}

class CacheDecoder extends Converter<String, dynamic> {
  final List<dynamic> _cache = [];

  void _reset() {
    _cache.clear();
  }

  CacheDecoder() {
    _reset();
  }

  @override
  dynamic convert(String input, {bool asMapKey = false, Parser? parser}) {
    if (_prefix == input[0] && input != MAP) {
      return _cache[_cacheDecode(input)];
    }
    var parsed = parser?.parseString(input) ?? input;
    if (_isCacheable(input, asMapKey)) {
      if (_cache.length == _maxEntries) {
        _reset();
      }
      _cache.add(parsed);
    }
    return parsed;
  }
}
