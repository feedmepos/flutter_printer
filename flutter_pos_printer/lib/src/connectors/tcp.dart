import 'dart:io';
import 'dart:typed_data';

import 'package:network_info_plus/network_info_plus.dart';

import 'package:flutter_pos_printer/discovery.dart';
import 'package:flutter_pos_printer/printer.dart';

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
    final List<PrinterDiscovered<TcpPrinterInfo>> result = [];
    final defaultPort = 9100;

    final String? deviceIp = await NetworkInfo().getWifiIP();
    if (deviceIp == null) return result;

    final String subnet = deviceIp.substring(0, deviceIp.lastIndexOf('.'));
    final List<String> ips = List.generate(255, (index) => '$subnet.$index');

    await Future.wait(ips.map((ip) async {
      try {
        final _socket = await Socket.connect(ip, defaultPort,
            timeout: Duration(milliseconds: 50));
        _socket.destroy();
        result.add(PrinterDiscovered<TcpPrinterInfo>(
            name: ip, detail: TcpPrinterInfo(address: _socket.address)));
      } catch (e) {}
    }));
    return result;
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      final _socket = await Socket.connect(_host, _port, timeout: _timeout);
      _socket.add(Uint8List.fromList(bytes));
      await _socket.flush();
      _socket.destroy();
      return true;
    } catch (e) {
      return false;
    }
  }
}
