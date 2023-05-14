# transit-dart

### 0.8.90

- fixed async bug with single item convert

### 0.8.88

- drop collection package version from 1.17.1 to 1.17.0

### 0.8.86

- update build program

### 0.8.84

- added build script

### 0.8.81

- Updates to support transit-cljd.
- Fixed bug with null as key in cmap.

### 0.8.79

- TransitCodec classes for public API.

### 0.8.76

- Updates to README.

### 0.8.71

- Fixed two bugs: (1) closing SplitterStreamSink output sink, (2) overwriting
  MessagePackEncoder buffer.

### 0.8.64

- Abstractions for splitter and combiner used by both Json and MessagePack
  encoders and decoders.

### 0.8.60

- Work on JsonRepeat(En/De)coder API.

### 0.8.53

- MessagePack testing.

### 0.8.51

- MessagePack encoding/decoding implemented and passes roundtrip test.


### 0.8.0-alpha

- Initial version. JSON reading and writing is supported and passes the
  roundtrip testing using `transit-format`'s `verify` test.

- The public API is not locked down, so tread carefully. Future breaking changes
  are very likely.