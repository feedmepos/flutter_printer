import 'package:flutter/foundation.dart';
import 'package:image/image.dart';

class DrawParams {
  final Image dst;
  final Image src;
  int? dstX;
  int? dstY;
  int? dstW;
  int? dstH;
  int? srcX;
  int? srcY;
  int? srcW;
  int? srcH;
  bool blend;

  DrawParams(this.dst, this.src,
      {this.dstX,
      this.dstY,
      this.dstW,
      this.dstH,
      this.srcX,
      this.srcY,
      this.srcW,
      this.srcH,
      this.blend = true});
}

Image _drawImage(DrawParams params) {
  return drawImage(params.dst, params.src,
      dstX: params.dstX,
      dstY: params.dstY,
      dstW: params.dstW,
      dstH: params.dstH,
      srcX: params.srcX,
      srcY: params.srcY,
      srcW: params.srcW,
      srcH: params.srcH,
      blend: params.blend);
}

Future<Image> drawImg(DrawParams params) async {
  return await compute(_drawImage, params);
}
