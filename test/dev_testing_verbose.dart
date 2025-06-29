import 'dart:convert';

import 'package:collection/collection.dart';

import 'package:transit_dart/src/handlers/write_handlers.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/codecs/semantic.dart';

var writeHandlers = WriteHandlers.json();
var readHandlers = ReadHandlers.json();

void main() {
  someOtherTests();
}

class Point {
  final int x;
  final int y;
  const Point(this.x, this.y);
  @override
  operator ==(other) => (other is Point) && other.x == x && other.y == y;
  @override
  get hashCode => x.hashCode * y.hashCode;
}

class PointWriteHandler extends WriteHandler<Point, List> {
  @override
  String tag(obj) => 'point';
  @override
  List rep(obj, {String? tag}) => [obj.x, obj.y];
}

class PointReadHandler extends ReadHandler<Point, List> {
  @override
  Point fromRep(rep) => Point(rep[0], rep[1]);
}

void someOtherTests() {
  var emitter = SemanticEncoder.jsonVerbose(
      customHandlers: {Class<Point>(): PointWriteHandler()});
  var parser = SemanticDecoder.jsonVerbose(
      customHandlers: {'point': PointReadHandler()});
  dynamic obj = bigObject;
  //dynamic obj = ["", "a", "ab", "abc", "abcd", "abcde", "abcdef"];
  // dynamic obj = bigObject;
  //dynamic obj = {null: null};
  //dynamic obj = "";
  //dynamic obj = Point(10, 15);
  print('obj is `$obj`');
  var emitted = emitter.convert(obj);
  print('emitted is `$emitted`');
  var encoded = json.encode(emitted);
  print('encoded is `$encoded`');
  var decoded = json.decode(encoded);
  print('decoded is `$decoded`');
  var parsed = parser.convert(decoded);
  print('parsed is `$parsed`');
  print(
      'Equal? ${DeepCollectionEquality(ZoneAgnosticEquality()).equals(parsed, obj)}');
}

var time =
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);

class ZoneAgnosticEquality extends DefaultEquality {
  @override
  bool equals(Object? e1, Object? e2) {
    if (e1 is DateTime && e2 is DateTime) {
      return e1.toUtc().isAtSameMomentAs(e2.toUtc());
    }
    return super.equals(e1, e2);
  }
}

var bigObject = [
  {'hello': true, 'there': null, 'you': true, 'cutie': 4.56},
  {'hello': 1, 'there': 2, 'you': 3, 'cutie': double.negativeInfinity},
  {null: 'hello', 4.56: '`there', true: '~you'},
  {4.56: '^cutie'},
  {
    [0, 'hello']: 1.1,
    'there': 2.2,
    'you': 3.3,
    'cutie': 4.4,
    null: "null test as cmap key",
    'point': Point(5, 7)
  },
  [
    'keyword',
    'ns-keyword',
    'symbol',
    //Symbol('db'),
    'BigInteger',
    'BigDecimal',
  ],
  Uri(path: 'http://www.詹姆斯.com/'),
  time,
  {
    'hello',
    'there',
    'you',
    'cutie',
  },
  //Uuid('b51241e0-c115-11ed-b737-370ae6e11809'),
];
