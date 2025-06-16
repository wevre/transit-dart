// Inspired by https://github.com/cognitect/transit-java/blob/master/src/test/java/com/cognitect/transit/TransitMPTest.java
import 'dart:async';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:transit_dart/src/codecs/msgpack.dart';
import 'package:transit_dart/src/codecs/transit.dart';
import 'package:transit_dart/src/handlers/read_handlers.dart';
import 'package:transit_dart/src/values/tagged_value.dart';

class UuidReadHandler extends ReadHandler<String, String> {
  String fromRep(String rep) => rep;
}

var msgpackEncoder = MessagePackEncoder();
var transitDecoder =
    TransitMessagePackCodec(customReadHandlers: {"u": UuidReadHandler()})
        .decoder;

readerOf(dynamic codedTransit) {
  return transitDecoder.convert(msgpackEncoder.convert(codedTransit));
}

void main() {
  test('testReadString', () {
    expect(readerOf("~~foo"), equals("~foo"));
    expect(readerOf("foo"), equals("foo"));
    expect(readerOf("~`foo"), equals("`foo"));
    expect(readerOf("~^foo"), equals("^foo"));
  });

  test('testReadBoolean', () {
    expect(readerOf("~?t"), equals(true));
    expect(readerOf("~?f"), equals(false));
    var m = readerOf({"~?t": 1, "~?f": 2});
    expect(m[true], equals(1));
    expect(m[false], equals(2));
  });

  test('testNull', () {
    expect(readerOf("~_"), equals(null));
  });

  test('testReadKeyword', () {
    expect(readerOf("~:foo"), equals(TaggedValue(":", "foo")));
    var l = readerOf(["~:foo", "^0", "^0"]);
    expect(l[0], equals(TaggedValue(":", "foo")));
    expect(l[1], equals(TaggedValue(":", "foo")));
    expect(l[2], equals(TaggedValue(":", "foo")));
  });

  // Not satisfied with the concrete BigDecimal implementation
  // test('testReadInteger', () {
  //     expect(readerOf("~i42"), equals(42));
  //     var r = readerOf("~n4256768765123454321897654321234567");
  //     expect((new BigInteger("4256768765123454321897654321234567")).compareTo((BigInteger)r.read()));
  // });

  test('testReadDouble', () {
    expect(readerOf("~d42.5"), 42.5);
  });

  test('testDateTime', () {
    var d = DateTime.timestamp();
    expect(readerOf("~t${d.toIso8601String()}"), equals(d));

    var m = {"~#m": d.millisecondsSinceEpoch};
    expect(
        readerOf(m).millisecondsSinceEpoch, equals(d.millisecondsSinceEpoch));
  });

  // test('testReadUUID', () {
  //   expect(readerOf("~u531a379e-31bb-4ce1-8690-158dceb64be6"));
  //     //equals("531a379e-31bb-4ce1-8690-158dceb64be6"));

  // });

  test('testReadUri', () {
    Uri uri = Uri.parse("https://github.com/tensegritics/ClojureDart");
    expect(
        readerOf("~rhttps://github.com/tensegritics/ClojureDart"), equals(uri));

    var httpsUri = Uri(
        scheme: 'https',
        host: 'dart.dev',
        path: '/guides/libraries/library-tour',
        fragment: 'numbers');

    expect(readerOf("~rhttps://dart.dev/guides/libraries/library-tour#numbers"),
        equals(httpsUri));
  });

  test('testReadSymbolAsTaggedValue', () {
    expect(readerOf("~\$foo"), equals(TaggedValue("\$", "foo")));
  });
}

// public void testReadBinary() throws IOException {

//         byte[] bytes = "foobarbaz".getBytes();
//         byte[] encodedBytes = Base64.getEncoder().encode(bytes);
//         byte[] decoded = readerOf("~b" + new String(encodedBytes)).read();

//         assertEquals(bytes.length, decoded.length);

//         boolean same = true;
//         for(int i=0;i<bytes.length;i++) {
//             if(bytes[i]!=decoded[i])
//                 same = false;
//         }

//         assertTrue(same);
//     }
