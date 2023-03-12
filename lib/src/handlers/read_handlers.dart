import 'dart:convert';
import 'dart:typed_data';
import 'package:fixed/fixed.dart';
import '../values/keyword.dart';
import '../values/link.dart';
import '../values/list.dart';
import '../values/symbol.dart';
import '../values/tagged_value.dart';
import '../values/uuid.dart';

abstract class ReadHandler<T, R> {
  T fromRep(R rep);
}

class ReadHandlersMap {
  final Map<String, ReadHandler> handlers;

  ReadHandler? getHandler(String tag) {
    return handlers[tag];
  }

  ReadHandlersMap.json() : handlers = Map.from(defaults);

  static final defaults = {
    '_': NullReadHandler(),
    '?': BooleanReadHandler(),
    'i': IntegerReadHandler(),
    'd': DoubleReadHandler(),
    'b': BinaryReadHandler(),
    ':': KeywordReadHandler(),
    '\$': SymbolReadHandler(),
    'f': BigDecimalReadHandler(),
    'n': BigIntegerReadHandler(),
    'm': TimeReadHandler(),
    't': VerboseTimeReadHander(),
    'u': UuidReadHandler(),
    'r': UriReadHandler(),
    'c': CharacterReadHandler(),
    "'": QuotedReadHandler(),
    'z': SpecialNumberReadHandler(),
    // TODO: we don't have 'array' and 'map' here
    'cmap': CmapReadHander(),
    'list': ListReadHandler(),
    'set': SetReadHandler(),
    'link': LinkReadHandler(),
  };
}

abstract class AbstractReadHandler<T> extends ReadHandler<T, dynamic> {}

// ignore: prefer_void_to_null
class NullReadHandler extends AbstractReadHandler<Null> {
  @override
  fromRep(rep) => null;
}

class BooleanReadHandler extends AbstractReadHandler<bool> {
  @override
  fromRep(rep) => 't' == rep;
}

class IntegerReadHandler extends AbstractReadHandler<int> {
  @override
  fromRep(rep) => int.parse(rep);
}

class DoubleReadHandler extends AbstractReadHandler<double> {
  @override
  fromRep(rep) => double.parse(rep);
}

class BinaryReadHandler extends AbstractReadHandler<Uint8List> {
  @override
  fromRep(rep) => base64.decode(rep);
}

class KeywordReadHandler extends AbstractReadHandler<Keyword> {
  @override
  fromRep(rep) => Keyword(rep);
}

class SymbolReadHandler extends AbstractReadHandler<Symbol> {
  @override
  fromRep(rep) => Symbol(rep);
}

class BigDecimalReadHandler extends AbstractReadHandler<Fixed> {
  @override
  fromRep(rep) => Fixed.tryParse(rep)!;
}

class BigIntegerReadHandler extends AbstractReadHandler<BigInt> {
  @override
  fromRep(rep) => BigInt.tryParse(rep)!;
}

class TimeReadHandler extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) => DateTime.fromMillisecondsSinceEpoch(rep);
}

class VerboseTimeReadHander extends AbstractReadHandler<DateTime> {
  @override
  fromRep(rep) => DateTime.parse(rep);
}

class UriReadHandler extends AbstractReadHandler<Uri> {
  @override
  fromRep(rep) => Uri.parse(rep);
}

class CharacterReadHandler extends AbstractReadHandler<String> {
  @override
  fromRep(rep) => rep;
}

class QuotedReadHandler extends AbstractReadHandler<Object> {
  @override
  fromRep(rep) => rep;
}

class SpecialNumberReadHandler extends AbstractReadHandler<double> {
  @override
  fromRep(rep) {
    if ('NaN' == rep) {
      return double.nan;
    } else if ('INF' == rep) {
      return double.infinity;
    } else if ('-INF' == rep) {
      return double.negativeInfinity;
    } else {
      throw Error();
    }
  }
}
