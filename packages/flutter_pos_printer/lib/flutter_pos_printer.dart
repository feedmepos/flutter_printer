library flutter_pos_printer;

export './src/connectors/android_usb.dart';
export 'src/connectors/tcp.dart';
export 'src/connectors/windows_spooler.dart';
export './src/printers/escpos.dart';
export './src/printers/star.dart';
export './src/printers/tspl.dart';
export './src/utils/utils.dart';

import 'package:flutter/services.dart';

const flutterPrinterChannel = const MethodChannel('flutter_pos_printer');
