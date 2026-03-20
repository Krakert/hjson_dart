/// Public API for decoding and encoding Hjson documents in Dart.
///
/// Example:
/// ```dart
/// import 'package:hjson_dart/hjson_dart.dart';
///
/// final value = hjsonDecode('name: hjson');
/// print(value['name']);
/// ```
library hjson_dart;

import 'package:hjson_dart/src/decoder.dart';
import 'package:hjson_dart/src/encoder.dart';

export 'src/hjson_error.dart' show HjsonDecodeError;
export 'src/decoder.dart' show HjsonDecoder;
export 'src/encoder.dart' show HjsonEncoder;

/// Decodes an Hjson string into a Dart object.
///
/// Example:
/// ```dart
/// final document = hjsonDecode('''
/// {
///   name: hjson
///   enabled: true
/// }
/// ''');
///
/// print(document['enabled']);
/// ```
///
/// Throws an `HjsonDecodeError` if the input is not valid Hjson.
dynamic hjsonDecode(String source, {bool strict = true}) {
  var decoder = HjsonDecoder(source, strict: strict);
  return decoder.decode();
}

/// Encodes a Dart object into an Hjson string.
///
/// Supported types: `String`, `num`, `bool`, `null`, `List`, and `Map`.
///
/// Example:
/// ```dart
/// final text = hjsonEncode({
///   'name': 'hjson',
///   'features': ['comments', 'multiline strings'],
/// });
///
/// print(text);
/// ```
///
/// - [indent]: The string used for indentation (default `'  '`).
/// - [emitRootBraces]: Whether to emit braces for the root object (default `true`).
/// - [quotes]: Controls quoting: `'minimal'` (default), `'all'`, `'always'`, `'keys'`, `'strings'`.
/// - [separator]: When `true`, commas are added after values (like JSON).
/// - [multiline]: Set to `'no-tabs'` to avoid tabs inside multiline strings.
String hjsonEncode(
  dynamic object, {
  String indent = '  ',
  bool emitRootBraces = true,
  String quotes = 'minimal',
  bool separator = false,
  String multiline = '',
}) {
  var encoder = HjsonEncoder(
    indent: indent,
    emitRootBraces: emitRootBraces,
    quotes: quotes,
    separator: separator,
    multiline: multiline,
  );
  return encoder.convert(object);
}
