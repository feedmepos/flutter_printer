import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as image;

class EscPosPrinter {
  EscPosPrinter();

  static late final Generator generator = Generator(null, null);

  static List<int> buildPulseDrawerCommand() {
    return [0x1b, 0x70, 0x00, 0x1e, 0xff, 0x00];
  }

  List<int> buildImageCommand(
      {required List<int> imageData,
      int width: 580,
      image.Interpolation interpolation: image.Interpolation.linear}) {
    print("buildImageCommand: $width");
    final decodedImage = image.decodeImage(imageData)!;
    final resizedImage = decodedImage.width != width
        ? image.copyResize(decodedImage,
            width: width, interpolation: image.Interpolation.linear)
        : decodedImage;

    final printerImage = generator.image(resizedImage);

    List<int> bytes = [];
    bytes += generator.reset();
    bytes += generator.setLineSpacing(0);
    bytes += printerImage;
    bytes += generator.resetLineSpacing();
    bytes += generator.cut();
    return bytes;
  }
}
