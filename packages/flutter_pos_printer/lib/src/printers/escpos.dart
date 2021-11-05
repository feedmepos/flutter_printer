import 'dart:typed_data';

import 'package:flutter_pos_printer/src/connectors/connector.dart';
import 'package:flutter_pos_printer/src/utils/escpos/generator.dart';
import 'package:image/image.dart';

import 'function.dart';
import 'printer.dart';

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
    final res = await connector.executor.execute(
        arg1: EscposPrintImageDto(image,
            width: width, dpi: dpi, threshold: threshold),
        fun1: printEscposImage);
    return await sendToConnector(() {
      List<int> bytes = [];
      bytes += generator.reset();
      bytes += generator.setLineSpacing(0);
      bytes += res.bytes;
      bytes += generator.resetLineSpacing();
      bytes += generator.cut();
      return bytes;
    }, delayMs: res.delayMs);
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
