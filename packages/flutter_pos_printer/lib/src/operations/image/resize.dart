import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class ResizeParams {
  final Image image;
  final int width;
  final int height;
  final Interpolation interpolation;
  ResizeParams(
    this.image, {
    required this.width,
    required this.height,
    this.interpolation = Interpolation.cubic,
  });
}

Image _resizeImage(ResizeParams params) {
  final resized = copyResize(params.image,
      width: params.width, interpolation: Interpolation.linear);

  return resized;
}

Future<Image> resizeImage(ResizeParams params) async {
  return await compute(_resizeImage, params);
}
