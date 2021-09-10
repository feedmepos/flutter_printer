import 'dart:io';

import 'package:flutter_html2image/flutter_html2image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('image generated', () async {
    final imageService = Html2Image();
    final image = await imageService.generateImage(
        content: buildDefaultTemplate(),
        paperWidth: 80,
        paperHeight: 0,
        dpi: 200,
        isTspl: false);
    await File('test.jpg').writeAsBytes(image.data);
    await imageService.dispose();
  });
}
