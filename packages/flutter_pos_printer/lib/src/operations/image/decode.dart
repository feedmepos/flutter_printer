import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class DecodeParams {
  final Uint8List bytes;
  DecodeParams({
    required this.bytes,
  });
}

class DecodeResult {
  final Image image;
  DecodeResult(this.image);
}

Image _decodeImage(Uint8List bytes) {
  return decodeImage(bytes)!;
}

Future<Image> decodeImg(Uint8List bytes) async {
  return await compute(_decodeImage, bytes);
}
