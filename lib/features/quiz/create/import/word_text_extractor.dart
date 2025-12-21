import 'dart:typed_data';

import 'package:docx_to_text/docx_to_text.dart';

String extractTextFromWord(Uint8List bytes) {
  return docxToText(bytes);
}

