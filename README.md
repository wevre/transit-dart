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

* Latest release: 0.8.0 -- this is alpha. The API is not fixed yet.

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

To run the roundtrip verification tests in `transit-format`, first ensure
Dart>=2.19.1 and Java 8 are installed, then do the following:

1. Set up a testing directory where all this can take place. The
   `transit-format` library and `transit-dart` library need to be side-by-side
   under the same parent directory. For example, create `transit-test` and
   inside clone [transit-format](https://github.com/cognitect/transit-format).

```sh
mkdir transit-test
cd transit-test
git clone https://github.com/cognitect/transit-format.git
# Do something similar to the following to ensure Java 8.
jenv local 1.8
```

2. Tell `transit-format` that the dart version is supported. In file
   `src/transit/verify.clj`, near line 350, make this change:

```clj
;; in file `transit-format/src/transit/verify.clj`
(def supported-impls #{"transit-clj"
                       "transit-cljs"
                       "transit-dart"   ;<-- insert this line
                       "transit-java"
                       "transit-jruby"
                       "transit-js"
                       "transit-python"
                       "transit-ruby"})
```

3. Copy `get-transit-dart` from `transit-dart/bin` into `transit-format/bin`.

```sh
curl "https://raw.githubusercontent.com/wevre/transit-dart/master/bin/get-transit-dart" > transit-format/bin/get-transit-dart
chmod +x transit-format/bin/get-transit-dart
```

4. Execute the verify command. The `verify` command will check for and, as
   necessary, clone `transit-dart`, run `dart pub get`, and compile
   `roundtrip.dart`.

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
