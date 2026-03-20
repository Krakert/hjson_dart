# hjson_dart

A Dart implementation of [HJSON](https://hjson.github.io/), a user interface for JSON. HJSON is a syntax extension that makes JSON more readable and writable for humans — comments, unquoted keys, multiline strings, and more.

Based on the reference [hjson-py](https://github.com/hjson/hjson-py) implementation.

## Features

- **Decode** HJSON (and standard JSON) into Dart objects
- **Encode** Dart objects into human-friendly HJSON
- Comments (`#`, `//`, `/* */`)
- Unquoted keys and values
- Multiline strings (`'''`)
- Root objects without braces
- Configurable quoting modes (`minimal`, `all`, `always`, `keys`, `strings`)
- Separator mode (comma-separated, more JSON-like)
- UTF-8 BOM stripping
- Surrogate pair decoding

## Getting started

Add `hjson_dart` as a dependency:

```yaml
dependencies:
  hjson_dart: ^0.1.1
```

## Usage

### Decoding

```dart
import 'package:hjson_dart/hjson_dart.dart';

final data = hjsonDecode('''
{
  # comments are supported
  name: hjson
  description: a user interface for JSON
  keywords: [hjson, json]
}
''');
print(data['name']); // hjson
```

### Encoding

```dart
import 'package:hjson_dart/hjson_dart.dart';

final hjson = hjsonEncode({
  'name': 'hjson',
  'version': 1,
  'features': ['comments', 'unquoted keys', 'multiline strings'],
});
print(hjson);
```

### Encoding options

```dart
hjsonEncode(data, indent: '\t');                // tab indentation
hjsonEncode(data, emitRootBraces: false);       // omit root { }
hjsonEncode(data, quotes: 'all');               // quote all keys and strings
hjsonEncode(data, separator: true);             // add commas between values
hjsonEncode(data, multiline: 'no-tabs');        // avoid tabs in multiline strings
```

### Error handling

```dart
try {
  hjsonDecode('{ broken');
} on HjsonDecodeError catch (e) {
  print(e.message); // error description
  print(e.line);    // 1-based line number
  print(e.column);  // 1-based column number
  print(e.offset);  // 0-based character offset
}
```

## Testing

Tests are ported from the [hjson-py](https://github.com/hjson/hjson-py/tree/master/hjson/tests) test suite.

### Run all tests

```sh
dart test
```

### Run a specific test file

```sh
dart test test/hjson_dart_test.dart    # asset-based decode/encode tests
dart test test/fail_test.dart          # failure/error cases
dart test test/unicode_test.dart       # Unicode and surrogate pairs
```

### Test files

| File | Description |
|------|-------------|
| `hjson_dart_test.dart` | Asset-based decode & encode tests from `testlist.txt` |
| `hjson_test.dart` | Same assets with CR/LF input variations (matches Python `test_hjson.py`) |
| `fail_test.dart` | Invalid JSON/HJSON documents that must raise errors |
| `pass1_test.dart` | JSON checker pass1 round-trip |
| `pass2_test.dart` | Deep nesting round-trip |
| `pass3_test.dart` | Object parsing round-trip |
| `decode_test.dart` | Decoder edge cases (whitespace, multiline, BOM) |
| `errors_test.dart` | Error object properties |
| `unicode_test.dart` | Unicode escapes, surrogate pairs, BOM stripping |
| `scanstring_test.dart` | String scanning, escape sequences, control characters |
| `float_test.dart` | Float, int, NaN, and Infinity handling |
| `dump_test.dart` | Encoding constants and round-trips |
| `separators_test.dart` | HJSON separator mode |
| `indent_test.dart` | Indentation options |

## Additional information

- HJSON specification: <https://hjson.github.io/>
- Reference implementation: <https://github.com/hjson/hjson-py>
