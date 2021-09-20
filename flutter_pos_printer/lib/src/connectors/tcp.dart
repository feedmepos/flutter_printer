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

class TcpPrinterConnector extends PrinterConnector {
  TcpPrinterConnector(this._host,
      {Duration timeout = const Duration(seconds: 5), port = 9100})
      : _port = port,
        _timeout = timeout;

  final String _host;
  final int _port;
  late final Duration _timeout;

  static DiscoverResult<TcpPrinterInfo> discoverPrinters() async {
    final List<PrinterDiscovered<TcpPrinterInfo>> result = [];
    final ip = await NetworkInfo().getWifiIP();

    final String subnet = ip!.substring(0, ip.lastIndexOf('.'));
    const port = 9100;
    for (var i = 0; i < 256; i++) {
      String ip = '$subnet.$i';
      await Socket.connect(ip, port, timeout: Duration(milliseconds: 50))
          .then((socket) async {
        await InternetAddress(socket.address.address).reverse().then((value) {
          result.add(PrinterDiscovered<TcpPrinterInfo>(
              name: value.host, detail: TcpPrinterInfo(address: value)));
        }).catchError((error) {
          print(socket.address.address);
          print('Error: $error');
        });
        socket.destroy();
      }).catchError((error) => null);
    }
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
