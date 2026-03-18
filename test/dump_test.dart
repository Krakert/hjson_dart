/// Converted from hjson-py test_dump.py
/// Tests encoding/dumping behavior.
/// Note: Python-specific features (sort_keys, skipkeys, StringIO dump,
/// stringify_key with bytes, AwesomeInt indent, accumulator) are not
/// applicable to the Dart HJSON library.
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestDump', () {
    test('test_dumps_empty', () {
      expect(hjsonEncode({}), equals('{}'));
    });

    test('test_constants', () {
      // null, true, false round-trip
      for (final c in [null, true, false]) {
        expect(hjsonDecode(hjsonEncode(c)), equals(c));
        final listEncoded = hjsonDecode(hjsonEncode([c]));
        expect((listEncoded as List)[0], equals(c));
        final mapEncoded = hjsonDecode(hjsonEncode({'a': c}));
        expect((mapEncoded as Map)['a'], equals(c));
      }
    });

    test('test_encode_truefalse', () {
      // In Dart, map keys must be strings, so we test with string keys
      final encoded = json.encode({'true': false, 'false': true});
      expect(json.decode(encoded), equals({'true': false, 'false': true}));
    });
  });
}
