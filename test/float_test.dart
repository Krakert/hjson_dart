/// Converted from hjson-py test_float.py
/// Tests float/int encoding and NaN/Infinity handling.
import 'dart:convert';
import 'dart:math';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestFloat', () {
    test('test_degenerates_ignore', () {
      // NaN and Infinity should encode to null in HJSON
      for (final f in [double.infinity, double.negativeInfinity, double.nan]) {
        final encoded = hjsonEncode(f);
        expect(encoded, equals('null'));
        expect(hjsonDecode(encoded), isNull);
      }
    });

    test('test_floats', () {
      // Float round-trip through JSON
      for (final num in [1617161771.7650001, pi, pow(pi, 100), pow(pi, -100), 3.1]) {
        final jsonStr = json.encode(num);
        expect(json.decode(jsonStr), equals(num));
      }
    });

    test('test_ints', () {
      // Int round-trip through JSON
      for (final num in [1, 1 << 32, 1 << 53]) {
        final jsonStr = json.encode(num);
        expect(jsonStr, equals(num.toString()));
        expect(json.decode(jsonStr), equals(num));
      }
    });
  });
}
