import 'dart:typed_data';

import 'package:esc_pos_utils_forked/esc_pos_utils_forked.dart';
import 'package:flutter_pos_printer/printer.dart';
import 'package:flutter_pos_printer/src/utils.dart';
import 'package:image/image.dart';

class EscPosPrinter extends GenericPrinter {
  EscPosPrinter(PrinterConnector connector,
      {this.dpi = 200, required this.width, this.beepCount = 4})
      : super(connector);

  final int width;
  final int dpi;
  final int beepCount;

  final Generator generator = Generator();

  @override
  Future<bool> beep() async {
    return await sendToConnector(() => generator.beepFlash(n: beepCount));
  }

  @override
  Future<bool> image(Uint8List image, {int threshold = 150}) async {
    final decodedImage = decodeImage(image)!;

    final converted = toPixel(
        ImageData(width: decodedImage.width, height: decodedImage.height),
        paperWidth: width,
        dpi: dpi,
        isTspl: false);

    final resizedImage = copyResize(decodedImage,
        width: converted.width, height: (converted.height * 2).toInt());

    final ms = 1000 + (converted.height * 0.5).toInt();

    return await sendToConnector(() {
      final printerImage = generator.image(resizedImage, threshold: threshold);
      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.setLineSpacing(0);
      bytes += printerImage;
      bytes += generator.resetLineSpacing();
      bytes += generator.cut();
      return bytes;
    }, delayMs: ms);
  }

  @override
  Future<bool> pulseDrawer() async {
    return await sendToConnector(() => [0x1b, 0x70, 0x00, 0x1e, 0xff, 0x00]);
  }

  @override
  Future<bool> selfTest() async {
    return true;
  }

  @override
  Future<bool> setIp(String ipAddress) async {
    return await sendToConnector(() => encodeSetIP(ipAddress));
  }
}
