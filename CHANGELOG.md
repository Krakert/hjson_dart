## 0.1.0

* Initial release with HJSON decoder and encoder.
* Decoder supports comments, unquoted keys and values, multiline strings,
  root objects without braces, UTF-8 BOM stripping, and surrogate pair decoding.
* Encoder supports configurable indentation, quoting modes (`minimal`, `all`,
  `always`, `keys`, `strings`), separator mode, and multiline string handling.
* `HjsonDecodeError` carries line, column, and offset for precise error reporting.
* Added example demonstrating decode, encode, encoding options, and error handling.
