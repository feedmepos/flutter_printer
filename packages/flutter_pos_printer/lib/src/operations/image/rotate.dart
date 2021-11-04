import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class RotateParams {
  Image image;
  num angle;
  Interpolation interpolation;
  RotateParams(
    this.image, {
    required this.angle,
    this.interpolation = Interpolation.cubic,
  });
}

Image _rotateImage(RotateParams params) {
  return copyRotate(params.image, params.angle,
      interpolation: params.interpolation);
}

Future<Image> rotateImage(RotateParams params) async {
  return await compute(_rotateImage, params);
}
