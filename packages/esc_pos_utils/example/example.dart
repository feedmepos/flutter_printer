import 'package:esc_pos_utils_forked/esc_pos_utils_forked.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart';

Future<void> main() async {
  final generator = Generator();
  List<int> bytes = [];

  // Print image:
  var data = await rootBundle.load('assets/logo.png');
  var imgBytes = data.buffer.asUint8List();
  var image = decodeImage(imgBytes);
  assert(image != null, "image cannot be null");
  bytes += generator.image(image!);

  bytes += generator.feed(2);
  bytes += generator.cut();
}
