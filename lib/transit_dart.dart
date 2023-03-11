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
    // TODO: I need a TaggedValueWriteHandler to deal with this 'cmap'.
    {
      [0, 'hello']: 1,
      'there': 2,
      'you': 3,
      'slime': 4
    }
  ], false));
}
