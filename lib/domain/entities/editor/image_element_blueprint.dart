import 'package:stickify/domain/entities/editor/element_blueprint.dart';

/// How an image should fit within its bounding box on the label canvas.
enum BlueprintBoxFit {
  /// Fill the target box completely.
  fill,

  /// Contain the image within the target box, preserving aspect ratio.
  contain,

  /// Cover the target box entirely, cropping if necessary.
  cover,

  /// Scale the image to fit the width.
  fitWidth,

  /// Scale the image to fit the height.
  fitHeight,

  /// Do not scale the image.
  none,
}

/// A blueprint element representing an image in the label template.
class ImageElementBlueprint extends ElementBlueprint {
  /// Creates a [ImageElementBlueprint] configuration.
  const ImageElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.fit,
    this.assetPath,
    this.networkUrl,
    this.localFilePath,
  });

  /// Optional path to a bundled flutter asset image.
  final String? assetPath;

  /// Optional web URL to load the image remotely.
  final String? networkUrl;

  /// Optional absolute path to a file stored locally on the device.
  final String? localFilePath;

  /// Fit rule specifying how the image should resize inside the dimensions.
  final BlueprintBoxFit fit;

  @override
  List<Object?> get props => [
        ...super.props,
        assetPath,
        networkUrl,
        localFilePath,
        fit,
      ];

  @override
  ImageElementBlueprint copyWith({
    String? id,
    double? x,
    double? y,
    double? width,
    double? height,
    double? rotation,
    String? assetPath,
    String? networkUrl,
    String? localFilePath,
    BlueprintBoxFit? fit,
  }) {
    return ImageElementBlueprint(
      id: id ?? this.id,
      x: x ?? this.x,
      y: y ?? this.y,
      width: width ?? this.width,
      height: height ?? this.height,
      rotation: rotation ?? this.rotation,
      assetPath: assetPath ?? this.assetPath,
      networkUrl: networkUrl ?? this.networkUrl,
      localFilePath: localFilePath ?? this.localFilePath,
      fit: fit ?? this.fit,
    );
  }
}
