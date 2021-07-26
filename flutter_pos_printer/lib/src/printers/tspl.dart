import 'dart:core';

import 'package:image/image.dart';

import 'backend.dart';

class ImageRaster {
  ImageRaster({required this.data, required this.width, required this.height});

  final List<int> data;
  final String width;
  final String height;
}

class Command {
  Command();

  static final String SIZE = "SIZE";
  static final String GAP = "GAP";
  static final String REFERENCE = "REFERENCE";
  static final String DIRECTION = "DIRECTION";
  static final String OFFSET = "OFFSET";
  static final String SHIFT = "SHIFT";

  // Action command
  static final String BEEP = "BEEP";
  static final String BITMAP = "BITMAP";
  static final String REVERSE = "REVERSE";
  static final String PRINT = "PRINT";
  static final List<int> SET_IP = [0x1f, 0x1b, 0x1f, 0x91, 0x00, 0x49, 0x50];
  static final String SELF_TEST_ETHERNET = "SELFTEST ETHERNET";

  static final String CLS = "CLS";
  static final String EOP = "EOP";

  static final String MILLIMETER = "mm";
  static final String DOT = "dot";
  static final String INCH = "";
  static final String SPACE = " ";
  static final String EOL = "\r\n";
  static final List<int> EOL_HEX = [0x0d, 0x0a];
  static final String COMMA = ",";

  static final int DPI200 = 8;
  static final int DPI300 = 12;

  static String setSize(String w, String h, String unit) {
    return createLine(SIZE, [w + unit, h + unit]);
  }

  static String setGap(String w, String h, String unit) {
    return createLine(GAP, [w + unit, h + unit]);
  }

  static String setReference(String x, String y) {
    return createLine(REFERENCE, [x, y]);
  }

  static String setDirection(String direction) {
    return createLine(DIRECTION, [direction]);
  }

  static String setOffset(String distance, String offset, String unit) {
    return createLine(OFFSET, [distance + unit, offset + unit]);
  }

  static String setShift(String shiftLeft, String shiftTop) {
    return createLine(SHIFT, [shiftLeft, shiftTop]);
  }

  static String imageString(
      String x, String y, String widthByte, String heightDot,
      {String mode = "0"}) {
    return createString(BITMAP, [x, y, widthByte, heightDot, mode, ""]);
  }

  static String reverse(
      String x, String y, String widthByte, String heightDot) {
    return createLine(REVERSE, [x, y, widthByte, heightDot]);
  }

  static String printIt(String copy, {String repeat = "1"}) {
    return createLine(PRINT, [copy, repeat]);
  }

  static String beep() {
    return createLine(BEEP, []);
  }

  static String selfTest() {
    return createLine(SELF_TEST_ETHERNET, []);
  }

  static String clearCache() {
    return createLine(CLS, []);
  }

  static String close() {
    return createLine(EOP, []);
  }

  static String createLine(String command, List<String> args) {
    return "${createString(command, args)} $EOL";
  }

  static String createString(String command, List<String> args) {
    return "$command ${args.join(COMMA)}";
  }
}

class TsplPrinter {
  TsplPrinter(
      {String unit = "mm",
      String sizeWidth = "35",
      String sizeHeight = "25",
      String gapDistance = "5",
      String gapOffset = "0",
      String referenceX = "0",
      String referenceY = "0",
      String direction = "0",
      String offset = "0",
      String offsetDistance = "0",
      String shiftLeft = "0",
      String shiftTop = "0"}) {
    this._unit = unit;
    this._sizeWidth = sizeWidth;
    this._sizeHeight = sizeHeight;
    this._gapDistance = gapDistance;
    this._gapOffset = gapOffset;
    this._referenceX = referenceX;
    this._referenceY = referenceY;
    this._direction = direction;
    this._offset = offset;
    this._offsetDistance = offsetDistance;
    this._shiftLeft = shiftLeft;
    this._shiftTop = shiftTop;
    this._config = [
      Command.setSize(this._sizeWidth, this._sizeHeight, this._unit),
      Command.setGap(this._gapDistance, this._gapOffset, this._unit),
      Command.setReference(this._referenceX, this._referenceY),
      Command.setDirection(this._direction),
      Command.setOffset(this._offsetDistance, this._offset, this._unit),
      Command.setShift(this._shiftLeft, this._shiftTop)
    ].join();
  }

  late final String _config;
  late final String _unit;
  late final String _sizeWidth;
  late final String _sizeHeight;
  late final String _gapDistance;
  late final String _gapOffset;
  late final String _referenceX;
  late final String _referenceY;
  late final String _direction;
  late final String _offset;
  late final String _offsetDistance;
  late final String _shiftLeft;
  late final String _shiftTop;

  List<int> _toImageCommand(List<int> rasterData, String widthByte,
      String heightDot, String x, String y,
      {String mode = "0",
      String copy = "1",
      String repeat = "1",
      bool beep = false}) {
    List<int> buffer = [];
    buffer += _convertStringToUTF16(this._config);
    buffer += _convertStringToUTF16(Command.clearCache());
    buffer += _convertStringToUTF16(
        Command.imageString(x, y, widthByte, heightDot, mode: mode));
    buffer += rasterData;
    buffer += Command.EOL_HEX;
    buffer += _convertStringToUTF16(Command.printIt(copy, repeat: repeat));
    if (beep) buffer += _convertStringToUTF16(Command.beep());
    buffer += _convertStringToUTF16(Command.close());
    return buffer;
  }

  static List<int> _convertStringToUTF16(String str) {
    return str.codeUnits;
  }

  static String beep() {
    return [Command.clearCache(), Command.beep(), Command.close()].join();
  }

  static String selfTest() {
    return [Command.clearCache(), Command.selfTest(), Command.close()].join();
  }

  List<int> buildImageCommand(
      {required List<int> imageData, required int dpi, bool beep = false}) {
    if (imageData.length > 0) {
      final decodedImage = decodeImage(imageData)!;
      final rasterizeImage = _toRaster(decodedImage, dpi: dpi);
      return _toImageCommand(rasterizeImage.data, rasterizeImage.width,
          rasterizeImage.height, "0", "0",
          beep: beep);
    } else {
      throw new Exception("imageData has no buffer size");
    }
  }

  List<int> generateTest() {
    List<int> buffer = [];
    buffer += _convertStringToUTF16(this._config);
    buffer += _convertStringToUTF16(Command.clearCache());
    buffer += _convertStringToUTF16(selfTest());
    buffer += Command.EOL_HEX;
    buffer += buffer += _convertStringToUTF16(
        Command.printIt(1.toString(), repeat: 1.toString()));
    buffer += _convertStringToUTF16(Command.close());
    return buffer;
  }

  ImageRaster _toRaster(Image imgSrc, {int dpi = 200}) {
    // 200 DPI : 1 mm = 8 dots
    // 300 DPI : 1 mm = 12 dots
    // width 35mm = 280px
    // height 25mm = 200px
    final int multiplier = dpi == 200 ? 8 : 12;
    final Image image = copyResize(imgSrc,
        width: int.parse(this._sizeWidth) * multiplier,
        height: int.parse(this._sizeHeight) * multiplier,
        interpolation: Interpolation.linear);
    final int widthPx = image.width;
    final int heightPx = image.height;
    final int widthBytes = widthPx ~/ 8; // one byte is 8 bits
    final List<int> imageBytes = image.getBytes(format: Format.argb);

    List<int> monoPixel = [];
    for (int i = 0; i < imageBytes.length; i += 4) {
      bool shouldBeWhite = imageBytes[i + 3] == 0 ||
          (imageBytes[i] > 100 &&
              imageBytes[i + 1] > 100 &&
              imageBytes[i + 2] > 100);
      monoPixel.add(shouldBeWhite ? 1 : 0);
    }

    List<int> rasterizeImage = [];
    for (int i = 0; i < monoPixel.length; i += 8) {
      if (i + 8 <= monoPixel.length) {
        String oneByte = monoPixel.sublist(i, i + 8).join();
        int packed = int.parse(oneByte, radix: 2);
        rasterizeImage.add(packed);
      }
    }

    return new ImageRaster(
        data: rasterizeImage,
        width: widthBytes.toString(),
        height: heightPx.toString());
  }
}
