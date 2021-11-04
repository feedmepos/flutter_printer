import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class FillParams {
  final Image image;
  final int color;
  FillParams(
    this.image, {
    required this.color,
  });
}

Image _fillImage(FillParams params) {
  return fill(params.image, params.color);
}

Future<Image> fillImage(FillParams params) async {
  return await compute(_fillImage, params);
}
