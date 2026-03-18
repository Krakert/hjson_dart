/// Converted from hjson-py test_pass2.py
import 'dart:convert';
import 'package:test/test.dart';
import 'package:hjson_dart/hjson_dart.dart';

// from http://json.org/JSON_checker/test/pass2.json
const _json = r'''
[[[[[[[[[[[[[[[[[[["Not too deep"]]]]]]]]]]]]]]]]]]]
''';

void main() {
  test('test_pass2', () {
    // test in/out equivalence and parsing
    final res = hjsonDecode(_json);
    final out = json.encode(res);
    expect(res, equals(json.decode(out)));
  });
}
