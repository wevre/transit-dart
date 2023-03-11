/// Support for doing something awesome.
///
/// More dartdocs go here.
library transit_dart;

import 'src/transit_dart_base.dart';

export 'src/transit_dart_base.dart';

var handlers = WriteHandlersMap.json();

void main() {
  var emitter = JsonEmitter(handlers, CacheEncoder());
  print('hello');
  print(emitter.emit([
    {'hello': true, 'there': null, 'you': true, 'slime': null},
    {'hello': 1, 'there': 2, 'you': 3, 'slime': 4},
    {null: 'hello', 1: 'there', true: 'you', 4.5: 'slime'},
    {
      [0, 'hello']: 1.1,
      'there': 2.2,
      'you': 3.3,
      'slime': 4.4
    }
  ], false));
}
