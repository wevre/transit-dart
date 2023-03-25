import 'package:collection/collection.dart';
import 'package:transit_dart/src/handlers/write_handlers.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/codecs/converters.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';
import 'package:transit_dart/src/values/big_decimal.dart';
import 'package:transit_dart/src/values/keyword.dart';
import 'package:transit_dart/src/values/link.dart';
import 'package:transit_dart/src/values/list.dart';
import 'package:transit_dart/src/values/symbol.dart';
import 'package:transit_dart/src/values/uuid.dart';
import 'package:transit_dart/src/values/uri.dart';

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

Future<void> someOtherTests() async {
  var emitter =
      TransitEncoder.messagePack(customHandlers: {Point: PointWriteHandler()});
  var parser =
      TransitDecoder.messagePack(customHandlers: {'point': PointReadHandler()});
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
  var decoded = await decoder.convert(encoded);
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
  {Keyword('my-key'): 13},
  {4.56: '^cutie'},
  {Keyword('my-key'): 14},
  {
    [0, 'hello']: 1.1,
    'there': 2.2,
    'you': 3.3,
    'cutie': 4.4,
    'point': Point(5, 7)
  },
  [
    'keyword',
    Keyword('test'),
    'ns-keyword',
    Keyword('transit/test'),
    'symbol',
    Symbol('db'),
    'BigInteger',
    BigInt.from(123456),
    'BigDecimal',
    BigDecimal.tryParse("-1.1E3")
  ],
  TransitUri('http://www.詹姆斯.com/'),
  Link(TransitUri(Uri(scheme: 'https', host: 'www.example.com').toString()),
      'a-rel',
      name: 'a-name', render: 'link', prompt: 'a-prompt'),
  Link(TransitUri(Uri(scheme: 'https', host: 'www.example.com').toString()),
      'a-rel',
      render: 'image'),
  time,
  {
    'hello',
    'there',
    'you',
    'cutie',
    Keyword('test'),
  },
  TransitList([
    'hello',
    'there',
    'you',
    'cutie',
    Keyword('transit/test'),
  ]),
  Uuid('b51241e0-c115-11ed-b737-370ae6e11809'),
  Uuid('5a2cbea3-e8c6-428b-b525-21239370dd55'),
];
