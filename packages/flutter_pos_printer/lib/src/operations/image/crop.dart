import 'package:image/image.dart';

class CropParams {
  Image image;
  int x;
  int y;
  int w;
  int h;
  CropParams(
    this.image, {
    required this.x,
    required this.y,
    required this.w,
    required this.h,
  });
}

Image _cropImage(CropParams params) {
  return copyCrop(params.image, params.x, params.y, params.w, params.h);
}

Future<Image> cropImage(CropParams params) async {
  return _cropImage(params);
}
