import 'package:test/test.dart';
import 'dart:io';
import 'dart:convert';
import 'package:hjson_dart/hjson_dart.dart';

const _assetsDir = 'test/assets';

/// Reads encoding options from a `_testmeta.hjson` file, if it exists.
Map<String, dynamic> _readOptions(String baseName) {
  final metaFile = File('$_assetsDir/${baseName}_testmeta.hjson');
  if (!metaFile.existsSync()) return {};
  final meta = hjsonDecode(metaFile.readAsStringSync()) as Map;
  return (meta['options'] as Map?)?.cast<String, dynamic>() ?? {};
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

  final testEntries = testListFile
      .readAsStringSync()
      .split('\n')
      .map((e) => e.trim())
      .where((e) => e.isNotEmpty)
      .toList();

  for (final entry in testEntries) {
    // testlist.txt may include subdirectory paths like "stringify/quotes_all_test.hjson"
    // All files are flattened into test/assets/ via unzip -j, so strip the dir prefix.
    final fileName = entry.split('/').last;

    String baseName;
    String ext;

    if (fileName.endsWith('_test.hjson')) {
      baseName = fileName.substring(0, fileName.length - '_test.hjson'.length);
      ext = '.hjson';
    } else if (fileName.endsWith('_test.json')) {
      baseName = fileName.substring(0, fileName.length - '_test.json'.length);
      ext = '.json';
    } else {
      continue;
    }

    final inputFile = File('$_assetsDir/${baseName}_test$ext');
    if (!inputFile.existsSync()) continue;

    if (baseName.startsWith('fail')) {
      // fail* tests must throw a decode error
      test('fail: $baseName', () {
        expect(
          () => hjsonDecode(inputFile.readAsStringSync()),
          throwsA(isA<HjsonDecodeError>()),
          reason: '$baseName should throw HjsonDecodeError',
        );
      });
    } else {
      final resultJsonFile = File('$_assetsDir/${baseName}_result.json');
      final resultHjsonFile = File('$_assetsDir/${baseName}_result.hjson');

      // Decode test: parse input, compare to _result.json
      test('decode: $baseName', () {
        final input = inputFile.readAsStringSync();
        final expected = json.decode(resultJsonFile.readAsStringSync());
        final actual = hjsonDecode(input);
        expect(
          json.encode(actual),
          equals(json.encode(expected)),
          reason: 'decode $baseName',
        );
      });

      // Encode test: encode _result.json with testmeta options, compare to _result.hjson
      if (resultHjsonFile.existsSync()) {
        test('encode: $baseName', () {
          final options = _readOptions(baseName);
          final value = json.decode(resultJsonFile.readAsStringSync());
          final expectedHjson = resultHjsonFile.readAsStringSync();

          final quotesOpt = (options['quotes'] as String?) ?? 'minimal';
          final separatorOpt = options['separator'] == true;
          final multilineOpt = (options['multiline'] as String?) ?? '';
          // legacyRoot: true means emit root braces (the default).
          // legacyRoot: false means omit root braces.
          final legacyRoot = options['legacyRoot'];
          final emitBraces = legacyRoot == false ? false : true;

          final actualHjson = hjsonEncode(
            value,
            quotes: quotesOpt,
            separator: separatorOpt,
            multiline: multilineOpt,
            emitRootBraces: emitBraces,
          );

          expect(actualHjson, equals(expectedHjson),
              reason: 'encode $baseName');
        });
      }
    }
  }
}
