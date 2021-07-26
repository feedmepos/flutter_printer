import 'dart:io';
import 'dart:typed_data';

class Tcp {
  Tcp(this._host, this._port, {Duration timeout = const Duration(seconds: 5)}) {
    this._timeout = timeout;
  }

  final String _host;
  final int _port;
  late final Duration _timeout;
  Socket? _socket;

  Future<bool> connect() async {
    try {
      if (_socket == null)
        _socket = await Socket.connect(_host, _port, timeout: _timeout);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> close() async {
    if (_socket != null) {
      await _socket!.flush();
      _socket!.destroy();
    }
  }

  void send(List<int> bytes) {
    if (_socket != null) _socket!.add(Uint8List.fromList(bytes));
  }
}
