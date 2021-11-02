/*
 * esc_pos_utils
 * Created by Andrey U.
 * 
 * Copyright (c) 2019-2020. All rights reserved.
 * See LICENSE for distribution and usage details.
 */

import 'dart:convert';
import 'dart:typed_data';

import 'package:esc_pos_utils_forked/esc_pos_utils_forked.dart';
import 'package:image/image.dart';

import 'commands.dart';
import 'enums.dart';

class Generator {
  Generator({this.spaceBetweenRows = 5});

  // Current styles
  PosStyles _styles = PosStyles();
  int spaceBetweenRows;

  /// Generate multiple bytes for a number: In lower and higher parts, or more parts as needed.
  ///
  /// [value] Input number
  /// [bytesNb] The number of bytes to output (1 - 4)
  List<int> _intLowHigh(int value, int bytesNb) {
    final dynamic maxInput = 256 << (bytesNb * 8) - 1;

    if (bytesNb < 1 || bytesNb > 4) {
      throw Exception('Can only output 1-4 bytes');
    }
    if (value < 0 || value > maxInput) {
      throw Exception(
          'Number is too large. Can only output up to $maxInput in $bytesNb bytes');
    }

    final List<int> res = <int>[];
    int buf = value;
    for (int i = 0; i < bytesNb; ++i) {
      res.add(buf % 256);
      buf = buf ~/ 256;
    }
    return res;
  }

  /// Extract slices of an image as equal-sized blobs of column-format data.
  ///
  /// [image] Image to extract from
  /// [lineHeight] Printed line height in dots
  List<List<int>> _toColumnFormat(Image imgSrc, int lineHeight) {
    final Image image = Image.from(imgSrc); // make a copy

    // Determine new width: closest integer that is divisible by lineHeight
    final int widthPx = (image.width + lineHeight) - (image.width % lineHeight);
    final int heightPx = image.height;

    // Create a black bottom layer
    final biggerImage = copyResize(image, width: widthPx, height: heightPx);
    fill(biggerImage, 0);
    // Insert source image into bigger one
    drawImage(biggerImage, image, dstX: 0, dstY: 0);

    int left = 0;
    final List<List<int>> blobs = [];

    while (left < widthPx) {
      final Image slice = copyCrop(biggerImage, left, 0, lineHeight, heightPx);
      final data = slice.data;
      final Uint8List bytes = Uint8List(slice.width * slice.height);
      final threshold = 100;
      for (var i = 0, len = data.length; i < len; ++i) {
        final int color = data[i];
        final int r = (color & 0x000000FF);
        final int g = (color & 0x0000FF00) >> 8;
        final int b = (color & 0x00FF0000) >> 16;
        bool shouldBeWhite = r > threshold && g > threshold && b > threshold;
        bytes[i] = shouldBeWhite ? 0 : 1;
      }
      blobs.add(bytes);
      left += lineHeight;
    }

    return blobs;
  }

  /// Image rasterization
  List<int> _toRasterFormat(Image imgSrc) {
    final Image image = Image.from(imgSrc); // make a copy
    final int widthPx = image.width;
    final int heightPx = image.height;

    grayscale(image);
    invert(image);

    // R/G/B channels are same -> keep only one channel
    final List<int> oneChannelBytes = [];
    final List<int> buffer = image.getBytes(format: Format.rgba);
    for (int i = 0; i < buffer.length; i += 4) {
      oneChannelBytes.add(buffer[i]);
    }

    // Add some empty pixels at the end of each line (to make the width divisible by 8)
    if (widthPx % 8 != 0) {
      final targetWidth = (widthPx + 8) - (widthPx % 8);
      final missingPx = targetWidth - widthPx;
      final extra = Uint8List(missingPx);
      for (int i = 0; i < heightPx; i++) {
        final pos = (i * widthPx + widthPx) + i * missingPx;
        oneChannelBytes.insertAll(pos, extra);
      }
    }

    // Pack bits into bytes
    return _packBitsIntoBytes(oneChannelBytes);
  }

  /// Merges each 8 values (bits) into one byte
  List<int> _packBitsIntoBytes(List<int> bytes) {
    const pxPerLine = 8;
    final List<int> res = <int>[];
    for (int i = 0; i < bytes.length; i += pxPerLine) {
      int newVal = 0;
      for (int j = 0; j < pxPerLine; j++) {
        newVal = _transformUint32Bool(
          newVal,
          pxPerLine - j,
          bytes[i + j],
        );
      }
      res.add(newVal ~/ 2);
    }
    return res;
  }

  /// Replaces a single bit in a 32-bit unsigned integer.
  int _transformUint32Bool(int uint32, int shift, int newValue) {
    return ((0xFFFFFFFF ^ (0x1 << shift)) & uint32) | (newValue << shift);
  }
  // ************************ (end) Internal helpers  ************************

  //**************************** Public command generators ************************
  /// Clear the buffer and reset text styles
  List<int> reset() {
    List<int> bytes = [];
    bytes += cInit.codeUnits;
    _styles = PosStyles();
    return bytes;
  }

  // Set line spacing (ESC 3)
  // Hex 1B 33 n
  // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=20
  List<int> setLineSpacing(int spacing) {
    List<int> bytes = [];
    bytes += [0x1b, 0x33, spacing];
    return bytes;
  }

  // Reset line spacing (ESC 2)
  // Hex 1B 32
  // https://reference.epson-biz.com/modules/ref_escpos/index.php?content_id=19
  List<int> resetLineSpacing() {
    List<int> bytes = [];
    bytes += [0x1b, 0x32];
    return bytes;
  }

  List<int> setStyles(PosStyles styles, {bool isKanji = false}) {
    List<int> bytes = [];
    if (styles.align != _styles.align) {
      bytes += latin1.encode(styles.align == PosAlign.left
          ? cAlignLeft
          : (styles.align == PosAlign.center ? cAlignCenter : cAlignRight));
      _styles = _styles.copyWith(align: styles.align);
    }

    if (styles.bold != _styles.bold) {
      bytes += styles.bold ? cBoldOn.codeUnits : cBoldOff.codeUnits;
      _styles = _styles.copyWith(bold: styles.bold);
    }
    if (styles.turn90 != _styles.turn90) {
      bytes += styles.turn90 ? cTurn90On.codeUnits : cTurn90Off.codeUnits;
      _styles = _styles.copyWith(turn90: styles.turn90);
    }
    if (styles.reverse != _styles.reverse) {
      bytes += styles.reverse ? cReverseOn.codeUnits : cReverseOff.codeUnits;
      _styles = _styles.copyWith(reverse: styles.reverse);
    }
    if (styles.underline != _styles.underline) {
      bytes +=
          styles.underline ? cUnderline1dot.codeUnits : cUnderlineOff.codeUnits;
      _styles = _styles.copyWith(underline: styles.underline);
    }

    return bytes;
  }

  /// Sens raw command(s)
  List<int> rawBytes(List<int> cmd, {bool isKanji = false}) {
    List<int> bytes = [];
    if (!isKanji) {
      bytes += cKanjiOff.codeUnits;
    }
    bytes += Uint8List.fromList(cmd);
    return bytes;
  }

  /// Skips [n] lines
  ///
  /// Similar to [feed] but uses an alternative command
  List<int> emptyLines(int n) {
    List<int> bytes = [];
    if (n > 0) {
      bytes += List.filled(n, '\n').join().codeUnits;
    }
    return bytes;
  }

  /// Skips [n] lines
  ///
  /// Similar to [emptyLines] but uses an alternative command
  List<int> feed(int n) {
    List<int> bytes = [];
    if (n >= 0 && n <= 255) {
      bytes += Uint8List.fromList(
        List.from(cFeedN.codeUnits)..add(n),
      );
    }
    return bytes;
  }

  /// Cut the paper
  ///
  /// [mode] is used to define the full or partial cut (if supported by the priner)
  List<int> cut({PosCutMode mode = PosCutMode.full}) {
    List<int> bytes = [];
    bytes += emptyLines(5);
    if (mode == PosCutMode.partial) {
      bytes += cCutPart.codeUnits;
    } else {
      bytes += cCutFull.codeUnits;
    }
    return bytes;
  }

  /// Beeps [n] times
  ///
  /// Beep [duration] could be between 50 and 450 ms.
  List<int> beep(
      {int n = 3, PosBeepDuration duration = PosBeepDuration.beep450ms}) {
    List<int> bytes = [];
    if (n <= 0) {
      return [];
    }

    int beepCount = n;
    if (beepCount > 9) {
      beepCount = 9;
    }

    bytes += Uint8List.fromList(
      List.from(cBeep.codeUnits)..addAll([beepCount, duration.value]),
    );

    beep(n: n - 9, duration: duration);
    return bytes;
  }

  List<int> beepFlash(
      {int n = 3,
      PosBeepDuration duration = PosBeepDuration.beep450ms,
      PosBeepFlashMode mode = PosBeepFlashMode.BuzzFlash}) {
    List<int> bytes = [];

    if (n <= 0) return [];

    int beepCount = n;
    if (beepCount > 20) beepCount = 20;

    bytes += Uint8List.fromList(List.from(cBeepFlash.codeUnits)
      ..addAll([beepCount, duration.value, mode.index]));
    return bytes;
  }

  /// Reverse feed for [n] lines (if supported by the priner)
  List<int> reverseFeed(int n) {
    List<int> bytes = [];
    bytes += Uint8List.fromList(
      List.from(cReverseFeedN.codeUnits)..add(n),
    );
    return bytes;
  }

  /// Print an image using (ESC *) command
  ///
  /// [image] is an instanse of class from [Image library](https://pub.dev/packages/image)
  Uint8ClampedList image(Image imgSrc, {PosAlign align = PosAlign.center}) {
    List<int> bytes = [];
    var startTime = DateTime.now().millisecondsSinceEpoch;

    // Image alignment
    bytes += setStyles(PosStyles().copyWith(align: align));

    final Image image = Image.from(imgSrc); // make a copy
    const bool highDensityHorizontal = true;
    const bool highDensityVertical = true;

    flip(image, Flip.horizontal);

    final Image imageRotated = copyRotate(image, 270);

    const int lineHeight = highDensityVertical ? 3 : 1;
    final List<List<int>> blobs = _toColumnFormat(imageRotated, lineHeight * 8);

    // Compress according to line density
    // Line height contains 8 or 24 pixels of src image
    // Each blobs[i] contains greyscale bytes [0-255]
    // const int pxPerLine = 24 ~/ lineHeight;
    for (int i = 0; i < blobs.length; i++) {
      blobs[i] = _packBitsIntoBytes(blobs[i]);
    }

    final int heightPx = imageRotated.height;
    const int densityByte =
        (highDensityHorizontal ? 1 : 0) + (highDensityVertical ? 32 : 0);

    final List<int> header = List.from(cBitImg.codeUnits);
    header.add(densityByte);
    header.addAll(_intLowHigh(heightPx, 2));

    // Adjust line spacing (for 16-unit line feeds): ESC 3 0x10 (HEX: 0x1b 0x33 0x10)
    //bytes += [27, 51, 16];
    for (int i = 0; i < blobs.length; ++i) {
      bytes += List.from(header)..addAll(blobs[i]);
    }

    // Reset line spacing: ESC 2 (HEX: 0x1b 0x32)
    //bytes += [27, 50];
    return Uint8ClampedList.fromList(bytes);
  }

  /// Open cash drawer
  List<int> drawer({PosDrawer pin = PosDrawer.pin2}) {
    List<int> bytes = [];
    if (pin == PosDrawer.pin2) {
      bytes += cCashDrawerPin2.codeUnits;
    } else {
      bytes += cCashDrawerPin5.codeUnits;
    }
    return bytes;
  }

  // ************************ (end) Public command generators ************************
}
