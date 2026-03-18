/// Converted from hjson-py test_hjson.py
/// Asset-based tests: parses testlist.txt and verifies decode/encode for each asset.
import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';
import 'package:hjson_dart/hjson_dart.dart';

const _assetsDir = 'test/assets';

String _load(String name, bool cr) {
  final path = '$_assetsDir/$name';
  String text = File(path).readAsStringSync();
  text = text.replaceAll('\r', '');
  if (cr) text = text.replaceAll('\n', '\r\n');
  return text;
}

Map<String, dynamic> _readOptions(String baseName) {
  final metaFile = File('$_assetsDir/${baseName}_testmeta.hjson');
  if (!metaFile.existsSync()) return {};
  final meta = hjsonDecode(metaFile.readAsStringSync()) as Map;
  return (meta['options'] as Map?)?.cast<String, dynamic>() ?? {};
}

void _check(String name, String file, bool inputCr) {
  final text = _load(file, inputCr);
  final shouldFail = name.startsWith('fail');

  if (shouldFail) {
    expect(
      () => hjsonDecode(text),
      throwsA(isA<HjsonDecodeError>()),
      reason: '$file should throw HjsonDecodeError (cr=$inputCr)',
    );
  } else {
    final data = hjsonDecode(text);

    final text1 = json.encode(data);
    final options = _readOptions(name);
    final quotesOpt = (options['quotes'] as String?) ?? 'minimal';
    final separatorOpt = options['separator'] == true;
    final multilineOpt = (options['multiline'] as String?) ?? '';
    final legacyRoot = options['legacyRoot'];
    final emitBraces = legacyRoot == false ? false : true;

    final hjson1 = hjsonEncode(
      data,
      quotes: quotesOpt,
      separator: separatorOpt,
      multiline: multilineOpt,
      emitRootBraces: emitBraces,
    );

    final result = json.decode(_load('${name}_result.json', inputCr));
    final text2 = json.encode(result);
    final hjson2 = _load('${name}_result.hjson', false);

    expect(text2, equals(text1), reason: '$file JSON roundtrip (cr=$inputCr)');
    expect(hjson2, equals(hjson1), reason: '$file HJSON encode (cr=$inputCr)');
  }
}

void main() {
  final assetsDir = Directory(_assetsDir);
  if (!assetsDir.existsSync()) {
    print('test/assets not found. Run test/download_tests.dart first.');
    return;
  }

  final testListFile = File('$_assetsDir/testlist.txt');
  if (!testListFile.existsSync()) {
    print('testlist.txt not found.');
    return;
  }

  final assets = testListFile
      .readAsStringSync()
      .replaceAll('\r', '')
      .split('\n')
      .where((e) => e.isNotEmpty)
      .toList();

  for (final file in assets) {
    // Strip directory prefixes (assets are flattened)
    final fileName = file.split('/').last;
    final sepIdx = fileName.indexOf('_test.');
    if (sepIdx < 0) continue;
    final name = fileName.substring(0, sepIdx);
    // Skip unsupported tests (as Python does)
    if (name.startsWith('quotes') && file.contains('stringify/')) continue;
    if (file.contains('extra/')) continue;

    test('asset: $name', () {
      _check(name, fileName, true);
      _check(name, fileName, false);
    });
  }
}
