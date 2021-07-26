import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html2image/flutter_html2image.dart';
import 'package:flutter_pos_printer/flutter_pos_printer.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {
    // If the widget was removed from the tree while the asynchronous platform
    // message was in flight, we want to discard the reply rather than calling
    // setState to update our non-existent appearance.
    if (!mounted) return;

    // Get a list of printers
    var printers = await PrinterBackend.getList(PrinterDriver.Usb);

    print("Android USB: ${printers.androidList.length}");
    printers.androidList.asMap().forEach((i, e) {
      print("[$i] Name: ${e.manufacturerName}");
      print("[$i] Name: ${e.productName}");
      print("[$i] Name: ${e.vendorId}"); // Required for connection
      print("[$i] Name: ${e.productId}"); // Required for connection
    });

    print("Windows PrintSpooler: ${printers.windowsList.length}");
    printers.windowsList.asMap().forEach((i, e) {
      print("[$i] Name: ${e.printerName}");
    });

    print("Star Printers: ${printers.starList.length}");
    printers.starList.asMap().forEach((i, e) {
      print("[$i] Name: ${e.portName}"); // Required for connection
      print("[$i] Name: ${e.modelName}");
    });

    // ESCPOS Network example
    final cashier = VirtualPrinter(
        driver: PrinterDriver.Network,
        type: PrinterType.ESCPOS,
        endpoint: "192.168.0.178");

    // Provide a HTML string
    // Width and height are im mm
    cashier.printHtml(HtmlInfo(buildDefaultTemplate(),
        paperWidth: 80,
        paperHeight: 0,
        paperGapDistance: 0,
        paperGapOffset: 0,
        paperXReference: 0,
        paperYReference: 0,
        paperDirection: 0,
        dpi: 200));

    cashier.pulseDrawer();

    // This printer is the same as the one above
    // because it has the same connection path(driver, endpoint)
    final kitchen = VirtualPrinter(
        driver: PrinterDriver.Network,
        type: PrinterType.ESCPOS,
        endpoint: "192.168.0.178");

    kitchen.sendTaskToQueue(() async {
      print("Hello World from kitchen");
    });

    kitchen.beepFlash(n: 3);

    // ESCPOS Windows USB example
    final escposUsb = VirtualPrinter(
        driver: PrinterDriver.Usb,
        type: PrinterType.ESCPOS,
        endpoint: "POS-80C");
    escposUsb.sendTaskToQueue(() async {
      print("Hello World from escposUsb");
    });

    // ESCPOS Android USB example
    final escposAndroid = VirtualPrinter(
        driver: PrinterDriver.Usb,
        type: PrinterType.ESCPOS,
        endpoint: PrinterBackend.encodeAndroidUSB(
            AndroidUsbConnection(vendorId: 1305, productId: 8211)),
        isAndroid: true);

    escposAndroid.setIp("192.168.0.200");

    final tsplWindows = VirtualPrinter(
        driver: PrinterDriver.Usb,
        type: PrinterType.TSPL,
        endpoint: "Gprinter GP-3150TN");

    tsplWindows.printHtml(HtmlInfo(buildDefaultTemplate(),
        paperWidth: 35,
        paperHeight: 25,
        paperGapDistance: 2,
        paperGapOffset: 0,
        paperXReference: 0,
        paperYReference: 0,
        paperDirection: 0,
        dpi: 200));

    tsplWindows.sendBytes(TsplPrinter.selfTest().codeUnits);

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text(''),
        ),
      ),
    );
  }
}
