import 'dart:async';
import 'dart:io';

import 'package:flutter_pos_printer/discovery.dart';
import 'package:flutter_pos_printer/printer.dart';

class AndroidUsbPrinterInfo {
  String vendorId;
  String productId;
  String manufacturer;
  String product;
  String name;
  String deviceId;
  AndroidUsbPrinterInfo({
    required this.vendorId,
    required this.productId,
    required this.manufacturer,
    required this.product,
    required this.name,
    required this.deviceId,
  });
}

class AndroidUsbPrinterConnector implements PrinterConnector {
  AndroidUsbPrinterConnector(this.vendorId, this.productId);

  final String vendorId;
  final String productId;

  static DiscoverResult<AndroidUsbPrinterInfo> discoverPrinters() async {
    if (Platform.isAndroid) {
      final List<dynamic> results =
          await flutterPrinterChannel.invokeMethod('getList');
      return results
          .map((dynamic r) => PrinterDiscovered<AndroidUsbPrinterInfo>(
                name: r['product'],
                detail: AndroidUsbPrinterInfo(
                  vendorId: r['vendorId'],
                  productId: r['productId'],
                  manufacturer: r['manufacturer'],
                  product: r['product'],
                  name: r['name'],
                  deviceId: r['deviceId'],
                ),
              ))
          .toList();
    }
    return [];
  }

  Future<bool> _connect() async {
    Map<String, dynamic> params = {"vendor": vendorId, "product": productId};
    return await flutterPrinterChannel.invokeMethod('connectPrinter', params) ==
            1
        ? true
        : false;
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      if (await _connect()) {
        Map<String, dynamic> params = {"bytes": bytes};
        return await flutterPrinterChannel.invokeMethod('printBytes', params) ==
                1
            ? true
            : false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
