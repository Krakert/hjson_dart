import 'hjson_error.dart';

final _numberRe =
    RegExp(r'^[\t ]*(-?(?:0|[1-9]\d*))(\.\d+)?([eE][-+]?\d+)?[\t ]*$');

/// Decodes Hjson text into standard Dart values.
///
/// Example:
/// ```dart
/// final decoder = HjsonDecoder('answer: 42');
/// final value = decoder.decode();
/// print(value['answer']);
/// ```
class HjsonDecoder {
  /// Input Hjson or JSON source text.
  final String source;

  /// Whether to use strict JSON-compatible parsing rules where applicable.
  final bool strict;
  int _index = 0;

  /// Creates a decoder for the provided [source].
  HjsonDecoder(this.source, {this.strict = true});

  /// Parses the configured source and returns the decoded Dart value.
  ///
  /// Example:
  /// ```dart
  /// final decoder = HjsonDecoder('[1, 2, 3]');
  /// final values = decoder.decode() as List<dynamic>;
  /// print(values.length);
  /// ```
  dynamic decode() {
    _index = 0;

    // strip UTF-8 BOM
    if (source.startsWith('\uFEFF')) {
      _index += 1;
    }

    int start = _index;
    String ch = _getNext();

    // If blank or comment only file, return empty dict
    if (start == 0 && ch.isEmpty) {
      return {};
    }

    dynamic obj;
    if (ch == '{' || ch == '[') {
      obj = _scanOnce(_index);
    } else {
      // assume root object without braces
      int backup = _index;
      try {
        obj = _parseObject(backup, objectWithoutBraces: true);
      } catch (e) {
        // Fallback to single value
        obj = _scanOnce(backup);
      }
    }

    // Check for extra data after end of value
    ch = _getNext();
    if (_index < source.length) {
      throw HjsonDecodeError('Extra data', source, _index);
    }

    return obj;
  }

  dynamic _scanOnce(int idx) {
    _index = idx;
    if (_index >= source.length) {
      throw HjsonDecodeError('Expecting value', source, _index);
    }

    String ch = source[_index];

    if (ch == '"' || ch == '\'') {
      if (_index + 2 < source.length &&
          source.substring(_index, _index + 3) == "'''") {
        return _parseMlString();
      } else {
        return _scanString();
      }
    } else if (ch == '{') {
      return _parseObject(_index + 1);
    } else if (ch == '[') {
      return _parseArray(_index + 1);
    }

    return _scanTfnns();
  }

  String _getNext() {
    while (_index < source.length) {
      String ch = source[_index];

      if (ch == ' ' || ch == '\t' || ch == '\n' || ch == '\r') {
        _index++;
        continue;
      }

      if (ch == '#' ||
          (ch == '/' &&
              _index + 1 < source.length &&
              source[_index + 1] == '/')) {
        _getEol();
        continue;
      } else if (ch == '/' &&
          _index + 1 < source.length &&
          source[_index + 1] == '*') {
        _index += 2;
        while (_index < source.length &&
            !(source[_index] == '*' &&
                _index + 1 < source.length &&
                source[_index + 1] == '/')) {
          _index++;
        }
        if (_index < source.length) {
          _index += 2;
        }
        continue;
      }

      return ch;
    }
    return '';
  }

  void _getEol() {
    while (_index < source.length) {
      String ch = source[_index];
      if (ch == '\r' || ch == '\n') {
        return;
      }
      _index++;
    }
  }

  int _skipIndent(int end, int n) {
    while (end < source.length &&
        (source[end] == ' ' || source[end] == '\t' || source[end] == '\r') &&
        (n > 0 || n < 0)) {
      end++;
      n--;
    }
    return end;
  }

  String _scanString() {
    String exitCh = source[_index];
    int begin = _index;
    _index++;
    StringBuffer chunks = StringBuffer();

    while (_index < source.length) {
      String ch = source[_index];
      if (ch == exitCh) {
        _index++;
        return chunks.toString();
      } else if (ch == '"' || ch == '\'') {
        chunks.write(ch);
        _index++;
      } else if (ch == '\\') {
        _index++;
        if (_index >= source.length) {
          throw HjsonDecodeError('Unterminated string', source, begin);
        }
        String esc = source[_index];
        if (esc == 'u') {
          if (_index + 4 >= source.length) {
            throw HjsonDecodeError(
                'Invalid \\uXXXX escape sequence', source, _index - 1);
          }
          String hex = source.substring(_index + 1, _index + 5);
          String hexX = hex.length > 1 ? hex[1] : '';
          if (hex.length != 4 || hexX == 'x' || hexX == 'X') {
            throw HjsonDecodeError(
                'Invalid \\uXXXX escape sequence', source, _index - 1);
          }
          int uni;
          try {
            uni = int.parse(hex, radix: 16);
          } catch (e) {
            throw HjsonDecodeError(
                'Invalid \\uXXXX escape sequence', source, _index - 1);
          }
          _index += 5;

          // Check for surrogate pair
          if (uni >= 0xD800 &&
              uni <= 0xDBFF &&
              _index + 1 < source.length &&
              source.substring(_index, _index + 2) == '\\u') {
            String esc2 = source.substring(_index + 2,
                _index + 6 > source.length ? source.length : _index + 6);
            String esc2X = esc2.length > 1 ? esc2[1] : '';
            if (esc2.length == 4 && esc2X != 'x' && esc2X != 'X') {
              try {
                int uni2 = int.parse(esc2, radix: 16);
                if (uni2 >= 0xDC00 && uni2 <= 0xDFFF) {
                  uni = 0x10000 + ((uni - 0xD800) << 10) + (uni2 - 0xDC00);
                  _index += 6;
                }
              } catch (_) {
                throw HjsonDecodeError(
                    'Invalid \\uXXXX escape sequence', source, _index);
              }
            }
          }
          chunks.writeCharCode(uni);
        } else {
          switch (esc) {
            case '"':
              chunks.write('"');
              break;
            case "'":
              chunks.write("'");
              break;
            case '\\':
              chunks.write('\\');
              break;
            case '/':
              chunks.write('/');
              break;
            case 'b':
              chunks.write('\b');
              break;
            case 'f':
              chunks.write('\f');
              break;
            case 'n':
              chunks.write('\n');
              break;
            case 'r':
              chunks.write('\r');
              break;
            case 't':
              chunks.write('\t');
              break;
            default:
              throw HjsonDecodeError(
                  'Invalid \\X escape sequence', source, _index);
          }
          _index++;
        }
      } else {
        if (strict && (ch.codeUnitAt(0) <= 0x1f)) {
          throw HjsonDecodeError('Invalid control character', source, _index);
        }
        chunks.write(ch);
        _index++;
      }
    }

    throw HjsonDecodeError('Unterminated string', source, begin);
  }

  String _parseMlString() {
    StringBuffer string = StringBuffer();
    int triple = 0;

    int indent = 0;
    for (int i = _index - 1; i >= 0; i--) {
      if (source[i] == '\n') break;
      indent++;
    }

    _index += 3;
    _index = _skipIndent(_index, -1);

    if (_index < source.length && source[_index] == '\n') {
      _index = _skipIndent(_index + 1, indent);
    }

    while (_index < source.length) {
      String ch = source[_index];
      if (ch == '\'') {
        triple++;
        _index++;
        if (triple == 3) {
          String result = string.toString();
          if (result.endsWith('\n')) {
            result = result.substring(0, result.length - 1);
          }
          return result;
        }
      } else {
        while (triple > 0) {
          string.write('\'');
          triple--;
        }
        if (ch == '\n') {
          string.write(ch);
          _index = _skipIndent(_index + 1, indent);
        } else {
          if (ch != '\r') {
            string.write(ch);
          }
          _index++;
        }
      }
    }

    throw HjsonDecodeError('Bad multiline string', source, _index);
  }

  String _scanKeyName() {
    String ch = _getNext();
    if (ch == '"' || ch == '\'') {
      return _scanString();
    }

    int begin = _index;
    int space = -1;

    while (_index < source.length) {
      ch = source[_index];
      if (ch == ':') {
        if (begin == _index) {
          throw HjsonDecodeError("Found ':' but no key name", source, begin);
        } else if (space >= 0) {
          if (space != _index - 1) {
            throw HjsonDecodeError(
                "Found whitespace in your key name", source, space);
          }
          return source.substring(begin, _index).trimRight();
        } else {
          return source.substring(begin, _index);
        }
      } else if (ch == ' ' || ch == '\t' || ch == '\r' || ch == '\n') {
        if (space < 0 || space == _index - 1) space = _index;
      } else if (ch == '{' ||
          ch == '}' ||
          ch == '[' ||
          ch == ']' ||
          ch == ',') {
        throw HjsonDecodeError(
            "Found '$ch' where a key name was expected", source, begin);
      }
      _index++;
    }
    throw HjsonDecodeError("Bad key name (eof)", source, _index);
  }

  dynamic _scanTfnns() {
    int begin = _index;
    String chf = _getNext();
    _index = begin;

    const punctuator = '{}[],:';
    if (punctuator.contains(chf)) {
      throw HjsonDecodeError(
          "Found a punctuator character when expecting a quoteless string",
          source,
          _index);
    }

    while (_index <= source.length) {
      String ch = _index < source.length ? source[_index] : '';
      bool isEol = ch == '\r' || ch == '\n' || ch == '';

      bool isComment = false;
      if (ch == '#' ||
          (ch == '/' &&
              _index + 1 < source.length &&
              (source[_index + 1] == '/' || source[_index + 1] == '*'))) {
        isComment = true;
      }

      if (isEol || ch == ',' || ch == '}' || ch == ']' || isComment) {
        String val = source.substring(begin, _index).trimRight();

        switch (chf) {
          case 'n':
            if (val == 'null') return null;
            break;
          case 't':
            if (val == 'true') return true;
            break;
          case 'f':
            if (val == 'false') return false;
            break;
          default:
            if (chf == '-' ||
                (chf.compareTo('0') >= 0 && chf.compareTo('9') <= 0)) {
              var match = _numberRe.firstMatch(val);
              if (match != null) {
                String integer = match.group(1) ?? '';
                String frac = match.group(2) ?? '';
                String exp = match.group(3) ?? '';
                if (frac.isNotEmpty || exp.isNotEmpty) {
                  num res = double.parse(integer + frac + exp);
                  if (res == res.toInt() && res.abs() < 1e10) {
                    return res.toInt();
                  }
                  return res;
                } else {
                  return int.parse(integer);
                }
              }
            }
        }

        if (isEol) {
          return source.substring(begin, _index).trim();
        }
      }
      _index++;
    }
    return source.substring(begin, _index).trim();
  }

  Map<String, dynamic> _parseObject(int startIdx,
      {bool objectWithoutBraces = false}) {
    _index = startIdx;
    Map<String, dynamic> pairs = {};

    String ch = _getNext();

    if (!objectWithoutBraces && ch == '}') {
      _index++;
      return pairs;
    }

    while (true) {
      String key = _scanKeyName();

      ch = _getNext();
      if (ch != ':') {
        throw HjsonDecodeError("Expecting ':' delimiter", source, _index);
      }
      _index++; // pass ':'

      _getNext(); // peek at next, but scanOnce ignores leading space anyway, actually _getNext consumes whitespace!
      // wait, scanOnce expects to NOT have whitespace consumed unless the tokens do?
      // Actually scanOnce starts by checking the first character. We must not consume the first character arbitrarily!

      var value = _scanOnce(_index);
      pairs[key] = value;

      ch = _getNext();
      if (ch == ',') {
        _index++;
        // ch = _getNext();
      }

      if (objectWithoutBraces) {
        ch = _getNext();
        if (ch == '') break;
      } else {
        ch = _getNext();
        if (ch == '}') {
          _index++;
          break;
        }
      }
    }
    return pairs;
  }

  List<dynamic> _parseArray(int startIdx) {
    _index = startIdx;
    List<dynamic> values = [];

    String ch = _getNext();

    if (ch == ']') {
      _index++;
      return values;
    } else if (ch == '') {
      throw HjsonDecodeError(
          "End of input while parsing an array", source, _index);
    }

    while (true) {
      dynamic value = _scanOnce(_index);
      values.add(value);

      ch = _getNext();
      if (ch == ',') {
        _index++;
      }

      ch = _getNext();
      if (ch == ']') {
        _index++;
        break;
      }
    }

    return values;
  }
}
