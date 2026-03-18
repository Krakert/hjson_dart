/// Converted from hjson-py test_fail.py
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

// JSON checker fail documents (strict mode)
// From http://json.org/JSON_checker/test/
final _jsonDocs = <String>[
  // fail2: Unclosed array
  '["Unclosed array"',
  // fail5: double extra comma
  '["double extra comma",,]',
  // fail6: missing value
  '[   , "<-- missing value"]',
  // fail7: Comma after the close
  '["Comma after the close"],',
  // fail8: Extra close
  '["Extra close"]]',
  // fail10: Extra value after close
  '{"Extra value after close": true} "misplaced quoted value"',
  // fail11: Illegal expression
  '{"Illegal expression": 1 + 2}',
  // fail12: Illegal invocation
  '{"Illegal invocation": alert()}',
  // fail13: Numbers cannot have leading zeroes
  '{"Numbers cannot have leading zeroes": 013}',
  // fail14: Numbers cannot be hex
  '{"Numbers cannot be hex": 0x14}',
  // fail15: Illegal backslash escape
  '["Illegal backslash escape: \\x15"]',
  // fail16: naked backslash
  '[\\naked]',
  // fail17: Illegal backslash escape
  '["Illegal backslash escape: \\017"]',
  // fail19: Missing colon
  '{"Missing colon" null}',
  // fail20: Double colon
  '{"Double colon":: null}',
  // fail21: Comma instead of colon
  '{"Comma instead of colon", null}',
  // fail22: Colon instead of comma
  '["Colon instead of comma": false]',
  // fail23: Bad value
  '["Bad value", truth]',
  // fail25: tab character in string
  '["\ttab\tcharacter\tin\tstring\t"]',
  // fail26: tab escape in string
  '["tab\\   character\\   in\\  string\\  "]',
  // fail27: line break in string
  '["line\nbreak"]',
  // fail28: line escape break
  '["line\\\nbreak"]',
  // fail29: 0e
  '[0e]',
  // fail30: 0e+
  '[0e+]',
  // fail31: 0e+-1
  '[0e+-1]',
  // fail32: Comma instead of closing brace
  '{"Comma instead if closing brace": true,',
  // fail33: mismatch
  '["mismatch"}',
  // control character in string
  '["A\u001FZ control characters in string"]',
  // misc based on coverage
  '{',
  '{]',
  '{"foo": "bar"]',
  '{"foo": "bar"',
];

void main() {
  group('TestFail', () {
    test('test_failures', () {
      for (var i = 0; i < _jsonDocs.length; i++) {
        final doc = _jsonDocs[i];
        expect(
          () => hjsonDecode(doc),
          throwsA(isA<HjsonDecodeError>()),
          reason:
              'Expected failure for doc $i: ${doc.length > 40 ? doc.substring(0, 40) : doc}',
        );
      }
    });

    test('test_array_decoder_issue46', () {
      // http://code.google.com/p/simplejson/issues/detail?id=46
      for (final doc in ['[,]']) {
        expect(
          () => hjsonDecode(doc),
          throwsA(isA<HjsonDecodeError>()),
          reason: "Unexpected success parsing '$doc'",
        );
      }
    });

    test('test_truncated_input', () {
      final testCases = <(String, String, int)>[
        ('[', 'End of input', 1),
        ('[42,', 'Expecting value', 4),
        ('["', 'Unterminated string', 1),
        ('["spam', 'Unterminated string', 1),
        ('["spam",', 'Expecting value', 8),
        ('{', 'Bad key name (eof)', 1),
        ('{"', 'Unterminated string', 1),
        ('{"spam', 'Unterminated string', 1),
        ('{"spam"', "Expecting ':'", 7),
        ('{"spam":', 'Expecting value', 8),
        ('{"spam":42,', 'Bad key name (eof)', 11),
        ('"', 'Unterminated string', 0),
        ('"spam', 'Unterminated string', 0),
        ('[,', 'Found a punctuator character', 1),
      ];

      for (final (data, msg, _) in testCases) {
        try {
          hjsonDecode(data);
          fail("Unexpected success parsing '$data'");
        } on HjsonDecodeError catch (e) {
          expect(
            e.msg.startsWith(msg) || e.msg.contains(msg),
            isTrue,
            reason: "'${e.msg}' doesn't contain '$msg' for '$data'",
          );
        }
      }
    });
  });
}
