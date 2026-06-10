import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

sealed class StickerSetupState extends Equatable {
  const StickerSetupState();

  @override
  List<Object?> get props => [];
}

class StickerSetupInitial extends StickerSetupState {
  const StickerSetupInitial();
}

class StickerSetupLoading extends StickerSetupState {
  const StickerSetupLoading();
}

class StickerSetupEditing extends StickerSetupState {
  const StickerSetupEditing({
    required this.widthMm,
    required this.heightMm,
    required this.cornerRadiusMm,
    required this.paddingTop,
    required this.paddingBottom,
    required this.paddingLeft,
    required this.paddingRight,
  });

  final double widthMm;
  final double heightMm;
  final double cornerRadiusMm;
  final double paddingTop;
  final double paddingBottom;
  final double paddingLeft;
  final double paddingRight;

  StickerConfig toConfig() {
    return StickerConfig(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      printableArea: [
        StickerPoint(paddingLeft, paddingTop),
        StickerPoint(widthMm - paddingRight, paddingTop),
        StickerPoint(widthMm - paddingRight, heightMm - paddingBottom),
        StickerPoint(paddingLeft, heightMm - paddingBottom),
      ],
    );
  }

  @override
  List<Object?> get props => [
        widthMm,
        heightMm,
        cornerRadiusMm,
        paddingTop,
        paddingBottom,
        paddingLeft,
        paddingRight,
      ];

  StickerSetupEditing copyWith({
    double? widthMm,
    double? heightMm,
    double? cornerRadiusMm,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
  }) {
    return StickerSetupEditing(
      widthMm: widthMm ?? this.widthMm,
      heightMm: heightMm ?? this.heightMm,
      cornerRadiusMm: cornerRadiusMm ?? this.cornerRadiusMm,
      paddingTop: paddingTop ?? this.paddingTop,
      paddingBottom: paddingBottom ?? this.paddingBottom,
      paddingLeft: paddingLeft ?? this.paddingLeft,
      paddingRight: paddingRight ?? this.paddingRight,
    );
  }
}

class StickerSetupSaving extends StickerSetupState {
  const StickerSetupSaving();
}

class StickerSetupSaved extends StickerSetupState {
  const StickerSetupSaved(this.templateId);

  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

class StickerSetupError extends StickerSetupState {
  const StickerSetupError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
