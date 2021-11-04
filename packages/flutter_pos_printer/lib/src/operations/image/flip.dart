import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class FlipParams {
  Image image;
  Flip mode;
  FlipParams(
    this.image, {
    required this.mode,
  });
}

Image _flipImage(FlipParams params) {
  return flip(params.image, params.mode);
}

Future<Image> flipImage(FlipParams params) async {
  return await compute(_flipImage, params);
}
