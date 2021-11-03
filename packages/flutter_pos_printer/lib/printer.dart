import 'dart:typed_data';

import 'package:flutter/services.dart';

final flutterPrinterChannel = const MethodChannel('flutter_pos_printer');

abstract class Printer {
  Future<bool> image(Uint8List image, {int threshold = 150});
  Future<bool> beep();
  Future<bool> pulseDrawer();
  Future<bool> setIp(String ipAddress);
  Future<bool> selfTest();
}

//
abstract class PrinterConnector {
  Future<bool> send(List<int> bytes);
}

abstract class GenericPrinter extends Printer {
  PrinterConnector connector;
  GenericPrinter(this.connector) : super();

  List<int> encodeSetIP(String ip) {
    List<int> buffer = [0x1f, 0x1b, 0x1f, 0x91, 0x00, 0x49, 0x50];
    final List<String> splittedIp = ip.split('.');
    return buffer..addAll(splittedIp.map((e) => int.parse(e)).toList());
  }

  Future<bool> sendToConnector(List<int> Function() fn, {int? delayMs}) async {
    final resp = await connector.send(fn());
    if (delayMs != null) {
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    return resp;
  }
}
