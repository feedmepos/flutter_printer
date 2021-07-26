import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

class Merger {
  static Future<Uint8List?> mergeImages(List<Uint8List> images,
      {int maxWidth = 300, bool fit = true, Color? backgroundColor}) async {
    int maxHeight = 0;
    int totalHeight = maxHeight;
    int totalWidth = maxWidth;
    ui.PictureRecorder recorder = ui.PictureRecorder();
    final paint = Paint();
    Canvas canvas = Canvas(recorder);
    double dx = 0;
    double dy = 0;
    if (backgroundColor != null)
      canvas.drawColor(backgroundColor, BlendMode.srcOver);
    List<ui.Image> imagesList = [];
    // Convert Uint8List image to Flutter Image widget
    images.forEach((image) async {
      imagesList.add(await Uint8ListToImage(image));
    });
    imagesList.forEach((image) {
      double scaleDx = dx;
      double scaleDy = dy;
      double imageHeight = image.height.toDouble();
      double imageWidth = image.width.toDouble();
      if (fit) {
        //scale the image to same width/height
        canvas.save();
        if (image.width != maxWidth) {
          canvas.scale(maxWidth / image.width);
          scaleDy *= imageWidth / maxWidth;
          imageHeight *= maxWidth / imageWidth;
        }
        canvas.drawImage(image, Offset(scaleDx, scaleDy), paint);
        canvas.restore();
      } else {
        //draw directly
        canvas.drawImage(image, Offset(dx, dy), paint);
      }
      dy += imageHeight;
      totalHeight += imageHeight.floor();
    });
    //output image
    return await ImageToUint8List(
        await recorder.endRecording().toImage(totalWidth, totalHeight));
  }

  static Future<Uint8List?> ImageToUint8List(ui.Image image,
      {ui.ImageByteFormat format = ui.ImageByteFormat.png}) async {
    ByteData? byteData = await image.toByteData(format: format);
    return byteData?.buffer.asUint8List();
  }

  static Future<ui.Image> Uint8ListToImage(Uint8List bytes) async {
    ImageProvider provider = MemoryImage(bytes);
    return await loadImageFromProvider(provider);
  }

  static Future<ui.Image> loadImageFromProvider(ImageProvider provider, {
    ImageConfiguration config = ImageConfiguration.empty,
  }) async {
    Completer<ui.Image> completer = Completer<ui.Image>();
    late ImageStreamListener listener;
    ImageStream stream = provider.resolve(config);
    listener = ImageStreamListener((ImageInfo frame, bool sync) {
      final ui.Image image = frame.image;
      completer.complete(image);
      stream.removeListener(listener);
    });
    stream.addListener(listener);
    return completer.future;
  }
}
