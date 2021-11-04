import 'dart:async';
import 'dart:io';

import 'package:flutter_pos_printer/flutter_pos_printer.dart';
import 'package:flutter_pos_printer/src/operations/discovery.dart';

import 'connector.dart';

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
  AndroidUsbPrinterConnector({required this.vendorId, required this.productId});

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
    Map<String, dynamic> params = {
      "vendor": int.parse(vendorId),
      "product": int.parse(productId)
    };
    return await flutterPrinterChannel.invokeMethod('connectPrinter', params);
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      final connected = await _connect();
      if (!connected) return false;
      Map<String, dynamic> params = {"bytes": bytes};
      return await flutterPrinterChannel.invokeMethod('printBytes', params);
    } catch (e) {
      return false;
    }
  }
}
