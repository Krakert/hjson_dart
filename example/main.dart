import 'package:hjson_dart/hjson_dart.dart';

void main() {
  // --- Decoding ---
  const source = r"""
{
  # This is a comment
  name: hjson_dart
  version: 1
  keywords: [
    hjson
    dart
    json
  ]
  description: A human-friendly extension of JSON
}
""";

  final data = hjsonDecode(source) as Map;
  print('name:        ${data['name']}');
  print('version:     ${data['version']}');
  print('keywords:    ${data['keywords']}');
  print('description: ${data['description']}');

  print('');

  // --- Encoding ---
  final output = hjsonEncode({
    'name': 'hjson_dart',
    'version': 1,
    'keywords': ['hjson', 'dart', 'json'],
  });
  print('Encoded HJSON:\n$output');

  // --- Encoding options ---
  final compact = hjsonEncode(
    {'key': 'value', 'number': 42},
    quotes: 'all',
    separator: true,
  );
  print('Compact (all quotes + separators):\n$compact');

  // --- Error handling ---
  try {
    hjsonDecode('{ broken');
  } on HjsonDecodeError catch (e) {
    print('Caught error: ${e.message} at line ${e.line}, column ${e.column}');
  }
}
