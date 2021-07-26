import 'dart:core';
import 'dart:io';
import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_pos_printer/flutter_pos_printer.dart';
import 'package:flutter_pos_printer/src/connectors/usb.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';

enum PrinterType { ESCPOS, TSPL }
enum PrinterDriver { Usb, Network, Star }

class AndroidUsbConnection {
  AndroidUsbConnection({required this.vendorId, required this.productId});

  final int vendorId;
  final int productId;
}

class Printers {
  var androidList = <AndroidUsb>[];
  var windowsList = <PrintSpooler>[];
  var starList = <PortInfo>[];
}

class PrinterBackend {
  PrinterBackend(this._connection, this._type, this._printerPath);

  Tcp? _tcp;
  late final PrinterDriver _connection;
  late final PrinterType _type;
  late final String _printerPath;

  static String encodePath(PrinterDriver connection, String path) {
    return [EnumToString.convertToString(connection), ":", path].join();
  }

  String decodePath() {
    var decoded =
        _printerPath.split("${EnumToString.convertToString(_connection)}:");
    if (decoded.length != 2) {
      throw new Exception("Path is not a valid Printer connection path");
    } else {
      return _printerPath
          .split("${EnumToString.convertToString(_connection)}:")[1];
    }
  }

  static String encodeAndroidUSB(AndroidUsbConnection usb) {
    return encodePath(PrinterDriver.Usb, '${usb.vendorId}_${usb.productId}');
  }

  AndroidUsbConnection decodeAndroidUSB() {
    String decoded = decodePath();
    var androidUsbDecoded = decoded.split("_");
    if (androidUsbDecoded.length != 2) {
      throw new Exception("Path is not a valid Android USB connection");
    } else {
      return AndroidUsbConnection(
          vendorId: int.parse(androidUsbDecoded[0]),
          productId: int.parse(androidUsbDecoded[1]));
    }
  }

  static Future<Printers> getList(PrinterDriver driver) async {
    var printers = Printers();
    switch (driver) {
      case PrinterDriver.Usb:
        var list = await UsbPluginRepo.getList();
        if (Platform.isAndroid) {
          printers.androidList.addAll(list as List<AndroidUsb>);
        }
        if (Platform.isWindows) {
          printers.windowsList.addAll(list as List<PrintSpooler>);
        }
        break;
      case PrinterDriver.Network:
        break;
      case PrinterDriver.Star:
        var list = await StarPrnt.portDiscovery(StarPortType.All);
        printers.starList.addAll(list);
        break;
    }
    return printers;
  }

  Future<void> connect() async {
    switch (_connection) {
      case PrinterDriver.Usb:
        if (Platform.isAndroid) {
          var androidUsb = decodeAndroidUSB();
          await UsbPluginRepo.connectAndroidUSBSerial(
              vendorId: androidUsb.vendorId, productId: androidUsb.productId);
        }

        if (Platform.isWindows)
          await UsbPluginRepo.connectWindowsPrintSpooler(decodePath());

        if (Platform.isIOS)
          throw new Exception("iOS does not support USB Printer.");
        break;
      case PrinterDriver.Network:
        if (_tcp == null) _tcp = new Tcp(decodePath(), 9100);
        await _tcp!.connect();
        break;
      case PrinterDriver.Star:
      //star.selectPrinter(decodePath());
        break;
    }
  }

  Future<bool> send(List<int> bytes) async {
    switch (_connection) {
      case PrinterDriver.Usb:
        if (Platform.isWindows || Platform.isAndroid) {
          await connect();
          return await UsbPluginRepo.printBytes(bytes);
        }

        if (Platform.isIOS)
          throw new Exception("iOS does not support USB Printer.");
        break;
      case PrinterDriver.Network:
        await connect();
        _tcp!.send(bytes);
        await _tcp!.close();
        return true;
      case PrinterDriver.Star:
        await connect();
    //return await star.printImage(bytes);
    }
    return false;
  }

  List<int> encodeImageForPrinter(Uint8List image, HtmlInfo printer) {
    switch (_type) {
      case PrinterType.ESCPOS:
        var escpos = EscPosPrinter();
        return escpos.buildImageCommand(
            imageData: image, width: printer.paperWidth);
      case PrinterType.TSPL:
        var tspl = TsplPrinter(
          unit: Command.MILLIMETER,
          sizeWidth: printer.paperWidth.toString(),
          sizeHeight: printer.paperHeight.toString(),
          gapDistance: printer.paperGapDistance.toString(),
          gapOffset: printer.paperGapOffset.toString(),
          referenceX: printer.paperXReference.toString(),
          referenceY: printer.paperYReference.toString(),
          direction: printer.paperDirection.toString(),
        );
        return tspl.buildImageCommand(imageData: image, dpi: printer.dpi);
    }
  }

  static List<List<int>> chunk(List<int> buffer, int chunkSize) {
    final int length = buffer.length;
    if (length > chunkSize) {
      final int chunkCount = length ~/ chunkSize;
      final int remainder = length % chunkSize;

      List<List<int>> chunks =
          List.filled(remainder > 0 ? chunkCount + 1 : chunkCount, []);
      for (int i = 0; i <= chunkCount; ++i) {
        bool isLast = length - (i * chunkSize) < chunkSize;

        int currentIndex = i * chunkSize;
        int endIndex = isLast
            ? currentIndex + (length - (chunkCount * chunkSize))
            : currentIndex + chunkSize;
        chunks[i] = buffer.sublist(currentIndex, endIndex);
      }
      return chunks;
    } else {
      return List.filled(1, buffer);
    }
  }

  static List<int> encodeSetIP(String ip) {
    final regex = new RegExp(r"(\d+)");
    if (regex.hasMatch(ip)) {
      List<int> buffer = [0x1f, 0x1b, 0x1f, 0x91, 0x00, 0x49, 0x50];
      final matches = regex.allMatches(ip);
      matches.forEach((match) {
        int ipMatch = int.parse(match.group(0)!);
        buffer.add(ipMatch);
      });
      return buffer;
    } else {
      throw new Exception("Invalid IP");
    }
  }
}
