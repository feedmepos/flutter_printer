import 'dart:io';
import 'dart:typed_data';

import 'package:network_info_plus/network_info_plus.dart';

import 'package:flutter_pos_printer/src/operations/discovery.dart';

import 'connector.dart';

class TcpPrinterInfo {
  InternetAddress address;
  TcpPrinterInfo({
    required this.address,
  });
}

class TcpPrinterConnector implements PrinterConnector {
  TcpPrinterConnector(this._host,
      {Duration timeout = const Duration(seconds: 5), port = 9100})
      : _port = port,
        _timeout = timeout;

  final String _host;
  final int _port;
  late final Duration _timeout;

  static DiscoverResult<TcpPrinterInfo> discoverPrinters() async {
    String? deviceIp = await NetworkInfo().getWifiIP();
    if (deviceIp == null) return [];

    final String subnet = deviceIp.substring(0, deviceIp.lastIndexOf('.'));

    final List<Future<PrinterDiscovered<TcpPrinterInfo>>> results =
        List.generate(255, (index) async {
      final host = '$subnet.$index';
      try {
        final _socket =
            await Socket.connect(host, 9100, timeout: Duration(seconds: 5));
        _socket.destroy();
        return PrinterDiscovered<TcpPrinterInfo>(
            name: host,
            detail: TcpPrinterInfo(address: _socket.address),
            exist: true);
      } catch (err) {
        return PrinterDiscovered(
            name: host,
            detail: TcpPrinterInfo(address: InternetAddress(host)),
            exist: false);
      }
    });
    final discovered = await Future.wait(results);
    return discovered.where((r) => r.exist).toList();
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      final _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _socket.add(Uint8List.fromList(bytes));
      await _socket.flush();
      await _socket.close();
      _socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}
