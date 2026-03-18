/// Converted from hjson-py test_indent.py
/// Note: The Python test tests JSON-level indent customization,
/// which is a simplejson feature. The Dart HJSON library uses its own
/// indent parameter for HJSON output.
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestIndent', () {
    test('test_hjson_indent', () {
      // Test that the Dart HJSON encoder respects the indent parameter
      final data = {'a': 1, 'b': 2};

      final result2 = hjsonEncode(data, indent: '  ');
      expect(result2.contains('  a'), isTrue);

      final resultTab = hjsonEncode(data, indent: '\t');
      expect(resultTab.contains('\ta'), isTrue);
    });

    test('test_json_indent_roundtrip', () {
      // JSON round-trip with indent
      final h = [
        ['blorpie'], ['whoops'], <dynamic>[],
        'd-shtaeou', 'd-nthiouh', 'i-vhbjkhnth',
        {'nifty': 87}, {'field': 'yes', 'morefield': false}
      ];
      final d1 = json.encode(h);
      final d2 = const JsonEncoder.withIndent('\t').convert(h);
      expect(json.decode(d1), equals(h));
      expect(json.decode(d2), equals(h));
    });
  });
}
