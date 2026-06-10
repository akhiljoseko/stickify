import 'package:stickify/domain/entities/editor/element_blueprint.dart';

enum BlueprintBoxFit { fill, contain, cover, fitWidth, fitHeight, none }

class ImageElementBlueprint extends ElementBlueprint {
  const ImageElementBlueprint({
    required super.id,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
    required super.rotation,
    required this.fit, this.assetPath,
    this.networkUrl,
    this.localFilePath, // Added for local file picker source support
  });

  final String? assetPath;
  final String? networkUrl;
  final String? localFilePath;
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
