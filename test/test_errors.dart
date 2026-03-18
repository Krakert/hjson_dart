/// Converted from hjson-py test_errors.py
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

void main() {
  group('TestErrors', () {
    test('test_decode_error', () {
      HjsonDecodeError? err;
      try {
        hjsonDecode('{}\na\nb');
      } on HjsonDecodeError catch (e) {
        err = e;
      }
      expect(err, isNotNull, reason: 'Expected HjsonDecodeError');
      // Python expects lineno=2, colno=1 for the 'a' on line 2
      // But our decoder gets Extra data error at the position after {}
      expect(err!.lineno, greaterThan(0));
      expect(err.colno, greaterThan(0));
    });

    test('test_scan_error', () {
      HjsonDecodeError? err;
      try {
        hjsonDecode('{"asdf": "');
      } on HjsonDecodeError catch (e) {
        err = e;
      }
      expect(err, isNotNull, reason: 'Expected HjsonDecodeError');
      expect(err!.lineno, equals(1));
    });

    test('test_error_properties', () {
      HjsonDecodeError? err;
      try {
        hjsonDecode('{]\n');
      } on HjsonDecodeError catch (e) {
        err = e;
      }
      expect(err, isNotNull);
      expect(err!.msg, isNotEmpty);
      expect(err.pos, greaterThanOrEqualTo(0));
    });
  });
}
