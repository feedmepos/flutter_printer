import 'dart:io';

import 'package:flutter_html2image/flutter_html2image.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final Html2Image imageService = Html2Image();

  tearDownAll(() async {
    await imageService.dispose();
  });

  test('tspl', () async {
    final image = await imageService.generateImage(
        content: buildDefaultTemplate(),
        paperWidth: 35,
        paperHeight: 25,
        dpi: 200,
        isTspl: true);
    expect(image.data.length, greaterThan(0));
    expect(image.height, greaterThan(0));
  });

  test('escpos', () async {
    final image = await imageService.generateImage(
        content: buildDefaultTemplate(),
        paperWidth: 80,
        paperHeight: 0,
        dpi: 200,
        isTspl: false);
    expect(image.data.length, greaterThan(0));
    expect(image.height, greaterThan(0));
  });
}
