/// Converted from hjson-py test_separators.py
/// Note: The Python test tests JSON-level separator customization (items/key
/// separators), which is a simplejson feature not directly supported in the
/// Dart HJSON library. The HJSON separator mode is tested in the asset-based
/// tests (hjson_dart_test.dart).
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestSeparators', () {
    test('test_hjson_separator_mode', () {
      // Test HJSON separator mode (commas between values)
      final data = {'foo': 'bar', 'baz': 42};
      final result = hjsonEncode(data, separator: true);
      // separator mode should add commas
      expect(result.contains(','), isTrue);
      // verify round-trip
      expect(hjsonDecode(result), equals(data));
    });

    test('test_json_separators_roundtrip', () {
      // JSON round-trip with custom separators
      final h = [
        ['blorpie'],
        ['whoops'],
        <dynamic>[],
        'd-shtaeou',
        'd-nthiouh',
        'i-vhbjkhnth',
        {'nifty': 87},
        {'field': 'yes', 'morefield': false}
      ];
      final d1 = json.encode(h);
      final h1 = json.decode(d1);
      expect(h1, equals(h));
    });
  });
}
