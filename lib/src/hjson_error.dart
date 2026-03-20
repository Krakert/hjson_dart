/// Exception thrown when Hjson parsing fails.
///
/// Example:
/// ```dart
/// try {
///   hjsonDecode('{ broken');
/// } on HjsonDecodeError catch (error) {
///   print('${error.message} at ${error.line}:${error.column}');
/// }
/// ```
class HjsonDecodeError implements Exception {
  /// Human-readable error message.
  final String message;

  /// Original input that failed to decode.
  final String source;

  /// Zero-based character offset where the error occurred.
  final int offset;

  /// Optional zero-based end offset for ranged parser errors.
  final int? endOffset;

  /// One-based line number where the error occurred.
  final int line;

  /// One-based column number where the error occurred.
  final int column;

  /// Creates a decode error and derives line and column information.
  HjsonDecodeError(this.message, this.source, this.offset, {this.endOffset})
      : line = _getLine(source, offset),
        column = _getColumn(source, offset);

  /// Alias for [message] matching the Python Hjson API.
  String get msg => message;

  /// Alias for [offset] matching the Python Hjson API.
  int get pos => offset;

  /// Alias for [endOffset] matching the Python Hjson API.
  int? get end => endOffset;

  /// Alias for [line] matching the Python Hjson API.
  int get lineno => line;

  /// Alias for [column] matching the Python Hjson API.
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
