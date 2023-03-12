/// Support for doing something awesome.
///
/// More dartdocs go here.
library transit_dart2;

import 'package:fixed/fixed.dart';
import 'package:uuid/uuid.dart' as yuli_uuid;

import 'src/transit_dart_base.dart';

export 'src/transit_dart_base.dart';

var handlers = WriteHandlersMap.json();

void main() {
  someTests();
}

void someTests() {
  var emitter = JsonEmitter(handlers, CacheEncoder());
  print(emitter.emit("hello"));
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
      BigInt.from(123.456),
      'BigDecimal',
      Fixed.fromNum(13.5)
    ],
    Uri(scheme: 'https', host: 'www.example.com'),
    Link(Uri(scheme: 'https', host: 'www.example.com'), 'a-rel',
        name: 'a-name', render: 'link', prompt: 'a-prompt'),
    Link(Uri(scheme: 'https', host: 'www.example.com'), 'a-rel',
        render: 'image'),
    DateTime.now(),
    {'hello', 'there', 'you', 'cutie'},
    TransitList(['hello', 'there', 'you', 'cutie']),
    Uuid(yuli_uuid.Uuid().v1()),
  ]));
}
