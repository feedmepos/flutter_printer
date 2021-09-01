import 'package:esc_pos_utils_forked/esc_pos_utils_forked.dart';
import 'package:flutter_html2image/flutter_html2image.dart';
import 'package:flutter_pos_printer/flutter_pos_printer.dart';
import 'package:queue/queue.dart';

typedef ConnectionPath = String;
typedef PrinterHtml = String;

class HtmlInfo {
  HtmlInfo(this.data,
      {required this.paperWidth,
      required this.paperHeight,
      required this.paperGapDistance,
      required this.paperGapOffset,
      required this.paperXReference,
      required this.paperYReference,
      required this.paperDirection,
      required this.dpi,
      this.backupToUsb,
      StarEmulation? emulationMode});

  final PrinterHtml data;

  final int paperWidth;
  final int paperHeight;
  final int paperGapDistance;
  final int paperGapOffset;
  final int paperXReference;
  final int paperYReference;
  final int paperDirection;
  final int dpi;

  bool? backupToUsb;
  StarEmulation? emulationMode;
}

class PrinterCore extends PrinterBackend {
  PrinterCore(PrinterDriver connection, PrinterType type, ConnectionPath path)
      : super(connection, type, path);

  final _imageGenerator = new Html2Image();
  final _queue = Queue();
}

class VirtualPrinter {
  /// Connection type [driver]
  ///
  /// Printer [type]
  ///
  /// Width [paperWidth] in px
  ///
  /// Endpoint [endpoint]
  ///
  /// Boolean [isAndroid]
  VirtualPrinter(
      {required PrinterDriver driver,
      required PrinterType type,
      required String endpoint,
      this.isAndroid = false}) {
    this.connection = driver;
    this.type = type;
    this.path =
        isAndroid ? endpoint : PrinterBackend.encodePath(driver, endpoint);
    init();
  }

  late final PrinterDriver connection;
  late final PrinterType type;
  late final ConnectionPath path;
  final bool isAndroid;

  get key => path;

  static final dictionary = Map<ConnectionPath, PrinterCore>();

  void init() {
    dictionary.update(this.path, (value) => value,
        ifAbsent: () => PrinterCore(this.connection, this.type, this.path));
  }

  PrinterCore? core() {
    return dictionary[key];
  }

  void sendTaskToQueue(Future Function() function) {
    core()?._queue.add(() => function.call());
  }

  void stopQueue() {
    core()?._queue.cancel();
  }

  void killAllQueue() {
    dictionary.forEach((key, value) {
      value._queue.dispose();
    });
  }

  Future<void> dispose() async {
    if (core() != null) {
      await core()!._imageGenerator.dispose();
      core()!._queue.dispose();
      dictionary.remove(key);
    }
  }

  /// Beep [n] times
  ///
  void beep({int n = 1}) {
    // codeUnits will convert ASCII String to List<int> bytes
    sendTaskToQueue(() async {
      if (type == PrinterType.TSPL)
        for (int i = 0; i < n; ++i) {
          await core()?.send(TsplPrinter.beep().codeUnits);
        }

      if (type == PrinterType.ESCPOS)
        await core()?.send(EscPosPrinter.generator.beep(n: n));
    });
  }

  /// Beep [n] times with PosBeepFlash [mode]
  void beepFlash(
      {int n = 1, PosBeepFlashMode mode = PosBeepFlashMode.BuzzFlash}) {
    if (type == PrinterType.ESCPOS)
      sendTaskToQueue(() async {
        await core()?.send(EscPosPrinter.generator.beepFlash(n: n, mode: mode));
      });
  }

  /// Instruct the printer to print a HTML content
  ///
  /// Printer [info]
  void printHtml(HtmlInfo info) {
    sendTaskToQueue(() async {
      if (core() != null) {
        bool isTsplPrinter = type == PrinterType.TSPL;
        await core()!._imageGenerator.initialize();
        // Load HTML
        await core()!._imageGenerator.loadHtml(info.data);
        // Generate a Uint8List image
        var results = await core()!._imageGenerator.generateImage(
            paperWidth: info.paperWidth,
            paperHeight: info.paperHeight,
            dpi: info.dpi,
            isTspl: isTsplPrinter);
        if (results.data.length > 0) {
          // Rebuild PrinterInfo object
          var printInfo = HtmlInfo(info.data,
              paperWidth: isTsplPrinter ? info.paperWidth : results.width,
              paperHeight: isTsplPrinter ? info.paperHeight : results.height,
              paperGapDistance: info.paperGapDistance,
              paperGapOffset: info.paperGapOffset,
              paperXReference: info.paperXReference,
              paperYReference: info.paperYReference,
              paperDirection: info.paperDirection,
              dpi: info.dpi);

          // Generate specific image command bytes for printer
          var printerImageBytes =
              core()!.encodeImageForPrinter(results.data, printInfo);
          final height = results.height;
          await core()!.send(printerImageBytes);
          await Future.delayed(
              Duration(milliseconds: 1000 + (height * 0.5).toInt()));
        }
      }
    });
  }

  void pulseDrawer() {
    sendTaskToQueue(() async {
      if (type == PrinterType.ESCPOS)
        await core()?.send(EscPosPrinter.buildPulseDrawerCommand());

      if (connection == PrinterDriver.Star) {
        //await core()?.star.openCashDrawer();
      }
    });
  }

  /// Instruct the printer to change its static IP
  ///
  /// IP Address [ip]
  void setIp(String ip) {
    sendTaskToQueue(() async {
      await core()?.send(PrinterBackend.encodeSetIP(ip));
      await Future.delayed(Duration(milliseconds: 200));
    });
  }

  /// Send printer command as bytes
  ///
  /// [List<int>] bytes
  void sendBytes(List<int> bytes) {
    sendTaskToQueue(() async {
      await core()?.send(bytes);
    });
  }
}
