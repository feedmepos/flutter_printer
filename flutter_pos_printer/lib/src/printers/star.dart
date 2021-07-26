import 'dart:typed_data';

import 'package:enum_to_string/enum_to_string.dart';
import 'package:flutter_star_prnt/flutter_star_prnt.dart';

import 'backend.dart';

enum StarEmulation { StarPRNT, StarLine, StarGraphic }

class StarPrinter {
  StarPrinter(PrinterDriver connection,
      {StarEmulation emulation = StarEmulation.StarGraphic, int width: 580}) {
    this._emulation = EnumToString.convertToString(emulation);
    this._width = width;
  }

  late final String _emulation;
  late final int _width;
  late final String? _selectedPrinter;

  Future<List<PortInfo>> getList(StarPortType type) async {
    return await StarPrnt.portDiscovery(type);
  }

  Future<PrinterResponseStatus> getStatus(String portName) async {
    return await StarPrnt.getStatus(portName: portName, emulation: _emulation);
  }

  void selectPrinter(String portName) {
    this._selectedPrinter = portName;
  }

  Future<bool> openCashDrawer() async {
    final commands = PrintCommands();
    commands.openCashDrawer(1);
    commands.openCashDrawer(2);
    final result = await StarPrnt.sendCommands(
        portName: this._selectedPrinter!,
        emulation: this._emulation,
        printCommands: commands);
    return result.isSuccess;
  }

  Future<bool> printImage(List<int> bytes) async {
    if (this._selectedPrinter == null) {
      throw new Exception(
          "No printer available, please connect before sending.");
    }
    final commands = PrintCommands();
    commands.appendBitmapByte(
        byteData: Uint8List.fromList(bytes),
        width: this._width,
        diffusion: true,
        bothScale: true,
        alignment: StarAlignmentPosition.Center);
    commands.appendCutPaper(StarCutPaperAction.PartialCutWithFeed);
    final result = await StarPrnt.sendCommands(
        portName: this._selectedPrinter!,
        emulation: this._emulation,
        printCommands: commands);
    return result.isSuccess;
  }
}
