/// Escape table for characters that must be escaped in quoted strings.
final Map<String, String> _escapeDct = () {
  final dct = <String, String>{
    '\\': '\\\\',
    '"': '\\"',
    '\b': '\\b',
    '\f': '\\f',
    '\n': '\\n',
    '\r': '\\r',
    '\t': '\\t',
  };
  for (var i = 0; i < 0x20; i++) {
    dct.putIfAbsent(String.fromCharCode(i),
        () => '\\u${i.toRadixString(16).padLeft(4, '0')}');
  }
  for (var i in [0x2028, 0x2029, 0xffff]) {
    dct.putIfAbsent(String.fromCharCode(i),
        () => '\\u${i.toRadixString(16).padLeft(4, '0')}');
  }
  return dct;
}();

class HjsonEncoder {
  final String indent;
  final bool emitRootBraces;
  final String quotes;
  final bool separator;
  final String multiline;

  HjsonEncoder({
    this.indent = '  ',
    this.emitRootBraces = true,
    this.quotes = 'minimal',
    this.separator = false,
    this.multiline = '',
  });

  // COMMONRANGE: Characters that should be escaped/avoided outside of basic printable range.
  // Matches Python's COMMONRANGE exactly.
  static const _commonRange =
      '\u007f-\u009f\u00ad\u0600-\u0604\u070f\u17b4\u17b5\u200c-\u200f\u2028-\u202f\u2060-\u206f\ufeff\ufff0-\uffff';

  static final _needsEscape = RegExp('[\\\\"\x00-\x1f$_commonRange]');
  static final _needsQuotes = RegExp(
      '^\\s|^"|^\'|^#|^/\\*|^//|^\\{|^\\}|^\\[|^\\]|^:|^,|\\s\$|[\x00-\x1f$_commonRange]');
  static final _needsEscapeMl =
      RegExp("'''|^[\\s]+\$|[\x00-\x08\x0b\x0c\x0e-\x1f$_commonRange]");
  static final _startsWithNumber = RegExp(
      r'^[\t ]*(-?(?:0|[1-9]\d*))(\.\d+)?([eE][-+]?\d+)?\s*((,|\]|\}|#|//|/\*).*)?$');
  static final _startsWithKeyword =
      RegExp(r'^(true|false|null)\s*((,|\]|\}|#|//|/\*).*)?$');
  static final _needsEscapeName = RegExp("[,\\{\\[\\}\\]\\s:#\"']|//|/\\*|'''");

  /// Encode a string with proper escaping (like JSON but using our escape table).
  static String _encodeBasestring(String s) {
    final buf = StringBuffer('"');
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      final esc = _escapeDct[ch];
      if (esc != null) {
        buf.write(esc);
      } else {
        final code = ch.codeUnitAt(0);
        if (code > 0x7e ||
            (code >= 0x7f && code <= 0x9f) ||
            code == 0xad ||
            (code >= 0x600 && code <= 0x604) ||
            code == 0x70f ||
            code == 0x17b4 ||
            code == 0x17b5 ||
            (code >= 0x200c && code <= 0x200f) ||
            (code >= 0x2028 && code <= 0x202f) ||
            (code >= 0x2060 && code <= 0x206f) ||
            code == 0xfeff ||
            (code >= 0xfff0 && code <= 0xffff)) {
          // Non-ASCII or COMMONRANGE: keep literal (ensure_ascii=False in Python)
          buf.write(ch);
        } else {
          buf.write(ch);
        }
      }
    }
    buf.write('"');
    return buf.toString();
  }

  String convert(dynamic object) {
    final chunks = <String>[];
    _iterencode(object, 0, true, chunks);
    return chunks.join();
  }

  void _iterencode(
      dynamic o, int indentLevel, bool isRoot, List<String> chunks) {
    if (o is String) {
      chunks.add(_encodeStr(o, indentLevel));
    } else if (o == null) {
      chunks.add('null');
    } else if (o == true) {
      chunks.add('true');
    } else if (o == false) {
      chunks.add('false');
    } else if (o is int) {
      chunks.add(o.toString());
    } else if (o is double) {
      if (o.isNaN || o.isInfinite) {
        chunks.add('null');
      } else {
        chunks.add(o.toString());
      }
    } else if (o is List) {
      _iterencodeList(o, indentLevel, isRoot, chunks);
    } else if (o is Map) {
      _iterencodeDict(o, indentLevel, isRoot, chunks);
    } else {
      throw ArgumentError('Unsupported type: ${o.runtimeType}');
    }
  }

  void _iterencodeList(
      List lst, int indentLevel, bool isRoot, List<String> chunks) {
    if (lst.isEmpty) {
      chunks.add('[]');
      return;
    }

    if (!isRoot) {
      chunks.add('\n${indent * indentLevel}');
    }

    indentLevel += 1;
    final newlineIndent = '\n${indent * indentLevel}';
    chunks.add('[');

    for (var i = 0; i < lst.length; i++) {
      chunks.add(newlineIndent);
      // In Python: _iterencode(value, _current_indent_level, True)
      // isRoot=True for list elements — containers don't add leading newline
      _iterencode(lst[i], indentLevel, true, chunks);
      if (separator && i < lst.length - 1) {
        chunks.add(',');
      }
    }

    if (separator) {
      // Remove trailing newline from last element if we need to add comma logic
      // Actually separators in Python HJSON test just add commas between items
    }

    indentLevel -= 1;
    chunks.add('\n${indent * indentLevel}');
    chunks.add(']');
  }

  void _iterencodeDict(
      Map dct, int indentLevel, bool isRoot, List<String> chunks) {
    if (dct.isEmpty) {
      chunks.add('{}');
      return;
    }

    // For non-root containers, emit leading newline + indent
    if (!isRoot) {
      chunks.add('\n${indent * indentLevel}');
    }

    bool showBraces = !isRoot || emitRootBraces;
    if (showBraces) {
      indentLevel += 1;
    }
    final newlineIndent = '\n${indent * indentLevel}';

    if (showBraces) {
      chunks.add('{');
    }

    final entries = dct.entries.toList();
    bool isFirst = true;
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final isLast = i == entries.length - 1;
      if (!isFirst || showBraces) {
        chunks.add(newlineIndent);
      }
      isFirst = false;

      String keyStr = entry.key.toString();
      chunks.add(_encodeKey(keyStr));

      // Collect value chunks to check if first chunk starts with \n
      var valueChunks = <String>[];
      _iterencode(entry.value, indentLevel, false, valueChunks);

      bool firstChunk = true;
      for (var chunk in valueChunks) {
        if (firstChunk) {
          firstChunk = false;
          if (chunk.startsWith('\n')) {
            chunks.add(':');
          } else {
            chunks.add(': ');
          }
        }
        chunks.add(chunk);
      }
      if (separator && !isLast) {
        chunks.add(',');
      }
    }

    if (showBraces) {
      indentLevel -= 1;
      chunks.add('\n${indent * indentLevel}');
      chunks.add('}');
    }
  }

  String _encodeKey(String key) {
    if (key.isEmpty) return '""';
    if (quotes == 'all' || quotes == 'keys') {
      return _encodeBasestring(key);
    }
    if (_needsEscapeName.hasMatch(key)) {
      return _encodeBasestring(key);
    }
    return key;
  }

  String _encodeStr(String str, int indentLevel) {
    if (str.isEmpty) return '""';

    // Force quoted strings when quotes option requires it,
    // or when separator mode is active (comma-separated = more JSON-like)
    if (quotes == 'all' ||
        quotes == 'always' ||
        quotes == 'strings' ||
        separator) {
      if (!_needsEscape.hasMatch(str)) {
        return '"$str"';
      } else {
        return _encodeBasestring(str);
      }
    }

    // Check if the string can be written as a quoteless string
    bool isNumber = false;
    if (str.isNotEmpty) {
      final first = str[0];
      if (first == '-' ||
          (first.codeUnitAt(0) >= 0x30 && first.codeUnitAt(0) <= 0x39)) {
        isNumber = _startsWithNumber.hasMatch(str);
      }
    }

    if (_needsQuotes.hasMatch(str) ||
        isNumber ||
        _startsWithKeyword.hasMatch(str)) {
      // Needs quotes — check if we can avoid escape sequences
      if (!_needsEscape.hasMatch(str)) {
        return '"$str"';
      } else if (!_needsEscapeMl.hasMatch(str) &&
          !(multiline == 'no-tabs' && str.contains('\t'))) {
        return _encodeStrMl(str, indentLevel + 1);
      } else {
        return _encodeBasestring(str);
      }
    }
    // Return without quotes
    return str;
  }

  String _encodeStrMl(String str, int indentLevel) {
    List<String> a = str.replaceAll('\r', '').split('\n');
    String gap = indent * indentLevel;

    if (a.length == 1) {
      return "'''${a[0]}'''";
    }

    final res = StringBuffer();
    res.write('\n$gap');
    res.write("'''");
    for (var line in a) {
      res.write('\n');
      if (line.isNotEmpty) {
        res.write(gap);
        res.write(line);
      }
    }
    res.write('\n$gap');
    res.write("'''");
    return res.toString();
  }
}
