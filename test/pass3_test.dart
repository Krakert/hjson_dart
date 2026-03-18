/// Converted from hjson-py test_pass3.py
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

// from http://json.org/JSON_checker/test/pass3.json
const _json = r'''
{
    "JSON Test Pattern pass3": {
        "The outermost value": "must be an object or array.",
        "In this test": "It is an object."
    }
}
''';

void main() {
  test('test_pass3', () {
    // test in/out equivalence and parsing
    final res = hjsonDecode(_json);
    final out = json.encode(res);
    expect(res, equals(json.decode(out)));
  });
}
