import 'package:collection/collection.dart';
import 'package:transit_dart/src/handlers/write_handlers.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/codecs/semantic.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';

var writeHandlers = WriteHandlers.messagePack();
var readHandlers = ReadHandlers.messagePack();

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
  var emitter =
      SemanticEncoder.messagePack(customHandlers: {Point: PointWriteHandler()});
  var parser = SemanticDecoder.messagePack(
      customHandlers: {'point': PointReadHandler()});
  var encoder = MessagePackEncoder();
  var decoder = MessagePackDecoder();
  dynamic obj = bigObject;
  //dynamic obj = ["", "a", "ab", "abc", "abcd", "abcde", "abcdef"];
  // dynamic obj = bigObject;
  //dynamic obj = {null: null};
  //dynamic obj = "";
  //dynamic obj = Point(10, 15);
  print('obj is `$obj`');
  var emitted = emitter.convert(obj);
  print('emitted is `$emitted`');
  var encoded = encoder.convert(emitted);
  print('encoded is `$encoded`');
  var decoded = decoder.convert(encoded);
  print('decoded is `$decoded`');
  var parsed = parser.convert(decoded);
  print('parsed is `$parsed`');
  print('Equal? ${DeepCollectionEquality().equals(parsed, obj)}');
}

var time =
    DateTime.fromMillisecondsSinceEpoch(DateTime.now().millisecondsSinceEpoch);

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
  Uri('http://www.詹姆斯.com/'),
  time,
  {
    'hello',
    'there',
    'you',
    'cutie',
  },
  Uuid('b51241e0-c115-11ed-b737-370ae6e11809'),
  Uuid('5a2cbea3-e8c6-428b-b525-21239370dd55'),
];
