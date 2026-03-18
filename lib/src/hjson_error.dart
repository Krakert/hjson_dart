class HjsonDecodeError implements Exception {
  final String message;
  final String source;
  final int offset;
  final int? endOffset;
  final int line;
  final int column;

  HjsonDecodeError(this.message, this.source, this.offset, {this.endOffset})
      : line = _getLine(source, offset),
        column = _getColumn(source, offset);

  /// Aliases matching Python hjson error properties.
  String get msg => message;
  int get pos => offset;
  int? get end => endOffset;
  int get lineno => line;
  int get colno => column;

  static int _getLine(String text, int offset) {
    if (offset < 0) return 0;
    if (offset > text.length) offset = text.length;
    var newlines = 0;
    for (var i = 0; i < offset; i++) {
      if (text[i] == '\n') newlines++;
    }
    return newlines + 1;
  }

  static int _getColumn(String text, int offset) {
    if (offset < 0) return 0;
    if (offset > text.length) offset = text.length;
    var column = 1;
    for (var i = offset - 1; i >= 0; i--) {
      if (text[i] == '\n') break;
      column++;
    }
    return column;
  }

  @override
  String toString() {
    return 'HjsonDecodeError: $message at line $line, column $column';
  }
}
