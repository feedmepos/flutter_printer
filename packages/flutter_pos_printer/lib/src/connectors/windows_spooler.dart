import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pos_printer/flutter_pos_printer.dart';
import 'package:flutter_pos_printer/src/operations/discovery.dart';
import 'package:worker_manager/worker_manager.dart';

import 'connector.dart';

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

class WindowsSpoolerPrinterConnector extends PrinterConnector {
  WindowsSpoolerPrinterConnector(this.printerName, {required Executor executor})
      : super(executor);

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
      final connected = await _connect();
      if (!connected) return false;
      Map<String, dynamic> params = {"bytes": Uint8List.fromList(bytes)};
      return await flutterPrinterChannel.invokeMethod('printBytes', params) == 1
          ? true
          : false;
    } catch (e) {
      await this._close();
      return false;
    }
  }
}
