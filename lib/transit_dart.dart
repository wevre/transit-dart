/// Support for doing something awesome.
///
/// More dartdocs go here.
library transit_dart2;

import 'package:fixed/fixed.dart';
//import 'package:uuid/uuid.dart' as yuli_uuid;

import 'src/transit_dart_base.dart';

export 'src/transit_dart_base.dart';

var writeHandlers = WriteHandlersMap.json();
var readHandlers = ReadHandlersMap.json();

void main() {
  // someTests();
  someOtherTests();
}

void someOtherTests() {
  var emitter = JsonEmitter(writeHandlers, CacheEncoder());
  var parser = JsonParser(readHandlers, CacheDecoder());
  //var obj = [1, 2, 3, "hello", "there", Keyword('test')];
  //var obj = "hello"; //{"hello": 1, "there": 2};
  var obj = [
    {'hello': true, 'there': null, 'you': true, 'cutie': 4.56},
    {'hello': 1, 'there': 2, 'you': 3, 'cutie': double.negativeInfinity},
    {null: 'hello', 4.56: '`there', true: '~you'},
    {Keyword('my-key'): 13},
    {4.56: '^cutie'},
    {Keyword('my-key'): 14},
    // {
    //   [0, 'hello']: 1.1,
    //   'there': 2.2,
    //   'you': 3.3,
    //   'cutie': 4.4
    // },
    // [
    //   'keyword',
    //   Keyword('test'),
    //   'ns-keyword',
    //   Keyword('transit/test'),
    //   'symbol',
    //   Symbol('db'),
    //   'BigInteger',
    //   BigInt.from(123456),
    //   'BigDecimal',
    //   Fixed.fromNum(13.5)
    // ],
    // Uri(scheme: 'https', host: 'www.example.com'),
    // Link(Uri(scheme: 'https', host: 'www.example.com').toString(), 'a-rel',
    //     name: 'a-name', render: 'link', prompt: 'a-prompt'),
    // Link(Uri(scheme: 'https', host: 'www.example.com').toString(), 'a-rel',
    //     render: 'image'),
    // DateTime.now(),
    // {
    //   'hello',
    //   'there',
    //   'you',
    //   'cutie',
    //   Keyword('test'),
    // },
    // TransitList([
    //   'hello',
    //   'there',
    //   'you',
    //   'cutie',
    //   Keyword('transit/test'),
    // ]),
    // Uuid('b51241e0-c115-11ed-b737-370ae6e11809'),
  ];
  var emitted = emitter.emit(obj);
  print('write cache is ${emitter.cache.getCache()}');
  print(parser.parse(emitted));
}

void someTests() {
  var emitter = JsonEmitter(writeHandlers, CacheEncoder());
  //print(emitter.emit("hello"));
  print(emitter.emit([
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
      'cutie': 4.4
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
      Fixed.fromNum(13.5)
    ],
    Uri(scheme: 'https', host: 'www.example.com'),
    Link(Uri(scheme: 'https', host: 'www.example.com').toString(), 'a-rel',
        name: 'a-name', render: 'link', prompt: 'a-prompt'),
    Link(Uri(scheme: 'https', host: 'www.example.com').toString(), 'a-rel',
        render: 'image'),
    DateTime.now(),
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
  ]));
}
