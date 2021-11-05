import 'dart:typed_data';

import 'package:flutter_pos_printer/src/operations/operations.dart';
import 'package:flutter_pos_printer/src/utils/escpos/escpos_utils.dart';
import 'package:image/image.dart';

abstract class PrintImageDto {
  final Uint8List image;
  final int width;
  final int dpi;
  final int threshold;
  PrintImageDto(
    this.image, {
    required this.width,
    required this.dpi,
    required this.threshold,
  });
}

abstract class PrintImageRes {
  final Uint8List bytes;
  final Image image;
  final int delayMs;
  PrintImageRes(
    this.bytes,
    this.image, {
    required this.delayMs,
  });
}

class EscposPrintImageDto implements PrintImageDto {
  final Uint8List image;
  final int width;
  final int dpi;
  final int threshold;
  EscposPrintImageDto(
    this.image, {
    required this.width,
    required this.dpi,
    required this.threshold,
  });
}

class EscposPrintImageRes implements PrintImageRes {
  final Uint8List bytes;
  final Image image;
  final int delayMs;
  EscposPrintImageRes(
    this.bytes,
    this.image, {
    required this.delayMs,
  });
}

PrintImageRes printEscposImage(PrintImageDto dto) {
  final decodedImage = decodeImage(dto.image)!;

  final converted = toPixel(
      ImageData(width: decodedImage.width, height: decodedImage.height),
      paperWidth: dto.width,
      dpi: dto.dpi,
      isTspl: false);

  final resized = copyResize(decodedImage,
      width: converted.width,
      height: converted.height,
      interpolation: Interpolation.cubic);

  final ms = 1000 + (converted.height * 0.5).toInt();

  final printerImage = Generator().image(resized, threshold: dto.threshold);
  return EscposPrintImageRes(printerImage, resized, delayMs: ms);
}
