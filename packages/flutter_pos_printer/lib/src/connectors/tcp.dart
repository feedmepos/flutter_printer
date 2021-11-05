import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_pos_printer/src/operations/discovery.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:worker_manager/worker_manager.dart';

import 'connector.dart';

class TcpSendDto {
  String ip;
  int port;
  Duration timeout;
  List<int> bytes;
  TcpSendDto(
    this.ip,
    this.port, {
    this.timeout = const Duration(seconds: 5),
    required this.bytes,
  });
}

Future<bool> _sendTcp(TcpSendDto dto) async {
  final _socket =
      await Socket.connect(dto.ip, dto.port, timeout: Duration(seconds: 5));
  _socket.add(Uint8List.fromList(dto.bytes));
  await _socket.flush();
  await _socket.close();
  _socket.destroy();
  return true;
}

class TcpPrinterInfo {
  InternetAddress address;
  TcpPrinterInfo({
    required this.address,
  });
}

class TcpPrinterConnector extends PrinterConnector {
  TcpPrinterConnector(this._host,
      {Duration timeout = const Duration(seconds: 5),
      port = 9100,
      required Executor executor})
      : _port = port,
        _timeout = timeout,
        super(executor);

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
      } on SocketException catch (e) {
        // printer may close our connection, but it is also connect success
        if (e.osError?.errorCode == null &&
            e.toString().contains('Socket has been closed')) {
          return PrinterDiscovered<TcpPrinterInfo>(
              name: host,
              detail: TcpPrinterInfo(address: InternetAddress(host)),
              exist: true);
        }

        return PrinterDiscovered<TcpPrinterInfo>(
            name: host,
            detail: TcpPrinterInfo(address: InternetAddress(host)),
            exist: false);
      } on Exception catch (e) {
        rethrow;
      }
    });
    final discovered = await Future.wait(results);
    return discovered.where((r) => r.exist).toList();
  }

  @override
  Future<bool> send(List<int> bytes) async {
    try {
      return await executor.execute(
          arg1: TcpSendDto(_host, _port, timeout: _timeout, bytes: bytes),
          fun1: _sendTcp);
    } catch (e) {
      return false;
    }
  }
}
