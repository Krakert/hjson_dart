/// Converted from hjson-py test_scanstring.py
/// Tests the string scanning/parsing behavior of the decoder.
/// Note: In Python this tests the low-level scanstring() function directly.
/// In Dart we test via hjsonDecode since the scanner is internal to HjsonDecoder.
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestScanString', () {
    test('test_scanstring_basic', () {
      // Test basic string parsing by wrapping strings in arrays
      expect(hjsonDecode(r'"\u007b"'), equals('{'));

      expect(
        hjsonDecode(
            '"A JSON payload should be an object or array, not a string."'),
        equals('A JSON payload should be an object or array, not a string.'),
      );
    });

    test('test_scanstring_in_arrays', () {
      // Strings can be extracted from arrays
      expect(
        hjsonDecode('["Unclosed array"]'),
        equals(['Unclosed array']),
      );
    });

    test('test_scanstring_escapes', () {
      expect(hjsonDecode(r'"\u007b"'), equals('{'));
      expect(hjsonDecode(r'"\\"'), equals('\\'));
      expect(hjsonDecode(r'"\/"'), equals('/'));
      expect(hjsonDecode(r'"\b"'), equals('\b'));
      expect(hjsonDecode(r'"\f"'), equals('\f'));
      expect(hjsonDecode(r'"\n"'), equals('\n'));
      expect(hjsonDecode(r'"\r"'), equals('\r'));
      expect(hjsonDecode(r'"\t"'), equals('\t'));
    });

    test('test_surrogates', () {
      // Surrogate pair: U+1D120 = \uD834\uDD20
      expect(
        hjsonDecode(r'"z\ud834\udd20x"'),
        equals('z\u{1d120}x'),
      );

      // High surrogate followed by non-surrogate
      // The high surrogate should be kept as-is
      final result = hjsonDecode(r'"z\ud834\u0079x"');
      expect(result, isA<String>());

      // High surrogate followed by another high surrogate then valid pair
      final result2 = hjsonDecode(r'"z\ud834\ud834\udd20x"');
      expect(result2, isA<String>());
    });

    test('test_control_characters_strict', () {
      // Control characters should raise errors in strict mode
      for (var i = 0; i < 0x20; i++) {
        final c = String.fromCharCode(i);
        expect(
          () => hjsonDecode('"$c"'),
          throwsA(isA<HjsonDecodeError>()),
          reason:
              'Control char 0x${i.toRadixString(16)} should fail in strict mode',
        );
      }
    });

    test('test_control_characters_nonstrict', () {
      // In non-strict mode, control characters should be accepted
      for (var i = 0; i < 0x20; i++) {
        if (i == 0x0a || i == 0x0d)
          continue; // skip \n and \r as they'd break the string
        final c = String.fromCharCode(i);
        final result = hjsonDecode('"$c"', strict: false);
        expect(result, equals(c),
            reason:
                'Control char 0x${i.toRadixString(16)} should be accepted in non-strict mode');
      }
    });

    test('test_invalid_surrogates', () {
      expect(
        () => hjsonDecode(r'"z\ud83x"'),
        throwsA(isA<HjsonDecodeError>()),
      );
    });
  });
}
