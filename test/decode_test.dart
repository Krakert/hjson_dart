/// Converted from hjson-py test_decode.py
/// Note: Python-specific features (parse_float, parse_int, object_pairs_hook,
/// raw_decode, bounds_checking, keys_reuse) are not applicable to the Dart
/// HJSON library and are omitted.
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestDecode', () {
    test('test_decoder_optimizations', () {
      // Whitespace handling around keys and values
      final rval = hjsonDecode('{   "key"    :    "value"    ,  "k":"v"    }');
      expect(rval, equals({'key': 'value', 'k': 'v'}));
    });

    test('test_empty_objects', () {
      expect(hjsonDecode('{}'), equals({}));
      expect(hjsonDecode('[]'), equals([]));
      expect(hjsonDecode('""'), equals(''));
    });

    test('test_empty_strings', () {
      expect(hjsonDecode('""'), equals(''));
      expect(hjsonDecode('[""]'), equals(['']));
    });

    test('test_multiline_string', () {
      final s1 = "\nhello: '''\n\n'''\n";
      final s2 = "\nhello: '''\n'''\n";
      final s3 = "\nhello: ''''''\n";
      final s4 = "\nhello: ''\n";
      final s5 = '\nhello: ""\n';
      expect(hjsonDecode(s1), equals({'hello': ''}));
      expect(hjsonDecode(s2), equals({'hello': ''}));
      expect(hjsonDecode(s3), equals({'hello': ''}));
      expect(hjsonDecode(s4), equals({'hello': ''}));
      expect(hjsonDecode(s5), equals({'hello': ''}));
    });

    test('test_strip_bom', () {
      // BOM should be stripped
      final content = '\u3053\u3093\u306b\u3061\u308f';
      final jsonDoc = '\uFEFF${json.encode(content)}';
      expect(hjsonDecode(jsonDoc), equals(content));
    });
  });
}
