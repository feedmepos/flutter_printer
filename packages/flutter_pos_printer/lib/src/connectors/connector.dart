import 'package:worker_manager/worker_manager.dart';

abstract class PrinterConnector {
  Executor executor;
  PrinterConnector(this.executor);
  Future<bool> send(List<int> bytes);
}
