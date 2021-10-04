import 'dart:typed_data';

import 'package:flutter/services.dart';

final flutterPrinterChannel = const MethodChannel('flutter_pos_printer');

abstract class Printer {
  Future<bool> image(Uint8List image);
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
    final regex = new RegExp(r"(\d+)");
    if (regex.hasMatch(ip)) {
      List<int> buffer = [0x1f, 0x1b, 0x1f, 0x91, 0x00, 0x49, 0x50];
      final matches = regex.allMatches(ip);
      matches.forEach((match) {
        int ipMatch = int.parse(match.group(0)!);
        buffer.add(ipMatch);
      });
      return buffer;
    } else {
      throw new Exception("Invalid IP");
    }
  }

  Future<bool> sendToConnector(List<int> Function() fn) async {
    return await connector.send(fn());
  }
}
