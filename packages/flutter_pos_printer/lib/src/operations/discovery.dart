import 'dart:io';

import 'package:flutter_pos_printer/flutter_pos_printer.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';

class PrinterDiscovered<T> {
  String name;
  T detail;
  bool exist;
  PrinterDiscovered(
      {required this.name, required this.detail, this.exist = true});
}

typedef DiscoverResult<T> = Future<List<PrinterDiscovered<T>>>;
typedef StarPrinterInfo = PortInfo;

DiscoverResult<StarPrinterInfo> discoverStarPrinter() async {
  if (Platform.isAndroid || Platform.isIOS) {
    return (await StarPrnt.portDiscovery(StarPortType.All))
        .map((e) => PrinterDiscovered<StarPrinterInfo>(
              name: e.modelName ?? 'Star Printer',
              detail: e,
            ))
        .toList();
  }
  return [];
}

Future<List<PrinterDiscovered>> discoverPrinters(
    {List<DiscoverResult Function()> modes = const [
      discoverStarPrinter,
      AndroidUsbPrinterConnector.discoverPrinters,
      WindowsSpoolerPrinterConnector.discoverPrinters,
      TcpPrinterConnector.discoverPrinters
    ]}) async {
  List<PrinterDiscovered> result = [];
  await Future.wait(modes.map((m) async {
    result.addAll(await m());
  }));
  return result;
}
