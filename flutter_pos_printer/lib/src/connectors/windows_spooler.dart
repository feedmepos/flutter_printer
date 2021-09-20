import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pos_printer/discovery.dart';
import 'package:flutter_pos_printer/printer.dart';

class WindowPrinterInfo {
  String name;
  String model;
  bool isDefault;
  WindowPrinterInfo({
    required this.name,
    required this.model,
    required this.isDefault,
  });
}

class WindowPrinterConnector implements PrinterConnector {
  WindowPrinterConnector(this.printerName);

  final String printerName;

  static DiscoverResult<WindowPrinterInfo> discoverPrinters() async {
    if (Platform.isWindows) {
      final List<dynamic> results =
          await flutterPrinterChannel.invokeMethod('getList');
      return results
          .map((dynamic result) => PrinterDiscovered<WindowPrinterInfo>(
                name: result['name'],
                detail: WindowPrinterInfo(
                    isDefault: result['default'],
                    name: result['name'],
                    model: result['model']),
              ))
          .toList();
    }
    return [];
  }

  Future<bool> _connect() async {
    Map<String, dynamic> params = {"name": printerName};
    return await flutterPrinterChannel.invokeMethod('connectPrinter', params) ==
            1
        ? true
        : false;
  }

  Future<bool> _close() async {
    return await flutterPrinterChannel.invokeMethod('close') == 1
        ? true
        : false;
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      if (await _connect()) {
        Map<String, dynamic> params = {"bytes": Uint8List.fromList(bytes)};
        return await flutterPrinterChannel.invokeMethod('printBytes', params) ==
                1
            ? true
            : false;
      }
      return false;
    } catch (e) {
      await this._close();
      return false;
    }
  }
}
