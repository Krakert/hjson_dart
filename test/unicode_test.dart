/// Converted from hjson-py test_unicode.py
/// Note: Python-specific features (encoding parameter, ensure_ascii, BytesIO,
/// object_pairs_hook) are not applicable to the Dart HJSON library.
/// Tests focus on Unicode decoding behavior that the Dart library supports.
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestUnicode', () {
    test('test_big_unicode_decode', () {
      // Surrogate pair decoding
      final u = 'z\u{1d120}x';
      expect(hjsonDecode('"z\\ud834\\udd20x"'), equals(u));
    });

    test('test_unicode_decode', () {
      // Decode \\uXXXX escape sequences for BMP range
      for (var i = 0x20; i < 0x80; i++) {
        final u = String.fromCharCode(i);
        final s = '"\\u${i.toRadixString(16).padLeft(4, '0')}"';
        expect(hjsonDecode(s), equals(u), reason: 'Failed for \\u${i.toRadixString(16).padLeft(4, '0')}');
      }
    });

    test('test_invalid_escape_sequences', () {
      // incomplete escape sequence
      expect(() => hjsonDecode('"\\u'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u1'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u12'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u123'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u1234'), throwsA(isA<HjsonDecodeError>()));

      // invalid escape sequence (invalid hex digits)
      expect(() => hjsonDecode('"\\u123x"'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u12x4"'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\u1x34"'), throwsA(isA<HjsonDecodeError>()));
      expect(() => hjsonDecode('"\\ux234"'), throwsA(isA<HjsonDecodeError>()));
    });

    test('test_strip_bom', () {
      final content = '\u3053\u3093\u306b\u3061\u308f';
      final jsonDoc = '\uFEFF${json.encode(content)}';
      expect(hjsonDecode(jsonDoc), equals(content));
    });
  });
}
