// Clean contract representation for a single platform feature capability.
// ignore_for_file: one_member_abstracts
import 'package:image_picker/image_picker.dart';

/// Abstraction for picking files/images from the platform device.
abstract class FilePickerService {
  /// Picks an image from the device's gallery and returns the local file path.
  Future<String?> pickImage();
}

/// Native implementation of [FilePickerService] using the `image_picker` package.
class ImagePickerServiceImpl implements FilePickerService {
  /// Creates an [ImagePickerServiceImpl] instance.
  const ImagePickerServiceImpl(this._picker);

  final ImagePicker _picker;

  @override
  Future<String?> pickImage() async {
    final image = await _picker.pickImage(source: ImageSource.gallery);
    return image?.path;
  }
}
