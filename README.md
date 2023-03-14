<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/guides/libraries/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-library-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/developing-packages).
-->
# transit-dart

Transit is a data format and set of libraries for conveying values between
applications written in different languages. This library provides support for
marshalling Transit data to/from Dart.

* [Rationale](https://blog.cognitect.com/blog/2014/7/22/transit)
* API docs coming soon
* [Specification](https://github.com/cognitect/transit-format)

This implementation's major.minor version number corresponds to the version of
the Transit specification it supports.

_NOTE: Transit is intended primarily as a wire protocol for transferring data
between applications. If storing Transit data durably, readers and writers are
expected to use the same version of Transit and you are responsible for
migrating/transforming/re-storing that data when and if the transit format
changes._

## Releases and Dependency Information

* Latest release: 0.8.0

## Getting started

TODO: Any Dart-specific installation things to mention here?

## Usage

TODO: This is a terrible example, even though it works, because you have to
cobble together the pieces by hand. In future we'll have a more friendly API
with examples showing how to convert directly to JSON or write to a stream.

```dart
import 'package:transit_dart/transit-dart';

var handlers = WriteHandlersMap.json();

void main() {
  var emitter = JsonEmitter(handlers, CacheEncoder());
  print(emitter.emit("hello"));
}
```

## Default Type Mapping

TODO: Provide table of transit semantic types mapped to Dart language objects.

## Testing

To run the roundtrip verification tests in `transit-format`:

1. Set up a testing directory where all this can take place. For example, call
   it `transit-test`. Clone
   [transit-format](https://github.com/cognitect/transit-format) to that
   directory.

```sh
mkdir transit-test
cd transit-test
git clone git@github.com:cognitect/transit-format
```

2. Copy the shell script [`bin/get-transit-dart`](https://github.com/wevre/transit-dart/blob/master/bin/get-transit-dart) from this repository
   to `transit-format/bin/get-transit-dart`.

```
curl 'https://raw.githubusercontent.com/wevre/transit-dart/master/bin/get-transit-dart' > transit-format/bin/get-transit-dart
```

3. Execute the verify command.

```
transit-format/bin/verify -impls dart -enc json
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.

## Copyright and License

Copyright © 2023 Mike Weaver

This library is a Dart port of the Java version created and maintained by
Cognitect, therefore

Copyright © 2014 Cognitect

TODO: Put in the Apache 2.0 license verbiage.
