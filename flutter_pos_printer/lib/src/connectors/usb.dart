import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';

class AndroidUsb {
  AndroidUsb(
      {required this.vendorId,
      required this.productId,
      required this.manufacturerName,
      required this.productName});

  final int vendorId;
  final int productId;
  final String manufacturerName;
  final String productName;
}

class PrintSpooler {
  PrintSpooler({required this.printerName});

  final String printerName;
}

class UsbPluginRepo {
  static const MethodChannel _channel =
      const MethodChannel('flutter_pos_printer');

  static Future<List<dynamic>> getList() async {
    final List<dynamic> results = await _channel.invokeMethod('getList');

    if (Platform.isAndroid) {
      final Iterable<AndroidUsb> usbDevices = results.map((e) => new AndroidUsb(
          vendorId: int.parse(e["vendorid"]),
          productId: int.parse(e["productid"]),
          manufacturerName: e["manufacturer"],
          productName: e["product"]));
     return usbDevices.toList();
    }

    if (Platform.isWindows) {
      final Iterable<PrintSpooler> printers =
          results.map((e) => new PrintSpooler(printerName: e["name"]));
      return printers.toList();
    }
    return [];
  }

  static Future<bool> connectAndroidUSBSerial(
      {required int vendorId, required int productId}) async {
    Map<String, dynamic> params = {"vendor": vendorId, "product": productId};
    return await _channel.invokeMethod('connectPrinter', params);
  }

  static Future<bool> connectWindowsPrintSpooler(String name) async {
    Map<String, dynamic> params = {"name": name};
    return await _channel.invokeMethod('connectPrinter', params) == 1
        ? true
        : false;
  }

  static Future<bool> close() async {
    return await _channel.invokeMethod('close') == 1 ? true : false;
  }

  static Future<bool> printBytes(List<int> bytes) async {
    // Android plugin only accepts Array<Integer>
    // Windows plugin accepts Uint8Array
    Map<String, dynamic> params = {
      "bytes": Platform.isAndroid ? bytes : Uint8List.fromList(bytes)
    };
    return await _channel.invokeMethod('printBytes', params) == 1
        ? true
        : false;
  }
}
