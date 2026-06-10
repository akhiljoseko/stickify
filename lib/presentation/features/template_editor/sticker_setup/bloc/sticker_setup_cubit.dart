import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_state.dart';

class StickerSetupCubit extends Cubit<StickerSetupState> {
  StickerSetupCubit(this._templateRepository, this.templateId)
      : super(const StickerSetupInitial());

  final TemplateRepository _templateRepository;
  final String templateId;

  Future<void> load() async {
    emit(const StickerSetupLoading());
    try {
      final template = await _templateRepository.fetchTemplate(templateId);
      final config = template.stickerConfig;
      
      if (config != null) {
        // Deconstruct printable area polygon to find padding
        // TL is (L, T)
        final tl = config.printableArea.isNotEmpty ? config.printableArea[0] : const StickerPoint(4, 4);
        final br = config.printableArea.length > 2 ? config.printableArea[2] : const StickerPoint(96, 56);
        
        final paddingLeft = tl.x;
        final paddingTop = tl.y;
        final paddingRight = config.widthMm - br.x;
        final paddingBottom = config.heightMm - br.y;

        // Verify if it is standard rectangle
        var isCustom = true;
        if (config.printableArea.length == 4) {
          final p0 = config.printableArea[0];
          final p1 = config.printableArea[1];
          final p2 = config.printableArea[2];
          final p3 = config.printableArea[3];
          
          final expectedP0 = StickerPoint(paddingLeft, paddingTop);
          final expectedP1 = StickerPoint(config.widthMm - paddingRight, paddingTop);
          final expectedP2 = StickerPoint(config.widthMm - paddingRight, config.heightMm - paddingBottom);
          final expectedP3 = StickerPoint(paddingLeft, config.heightMm - paddingBottom);

          const tol = 0.01;
          bool match(StickerPoint a, StickerPoint b) =>
              (a.x - b.x).abs() < tol && (a.y - b.y).abs() < tol;

          if (match(p0, expectedP0) &&
              match(p1, expectedP1) &&
              match(p2, expectedP2) &&
              match(p3, expectedP3)) {
            isCustom = false;
          }
        }

        final pointIds = List.generate(
          config.printableArea.length,
          (i) => 'point_${i}_${DateTime.now().microsecondsSinceEpoch}',
        );
        emit(StickerSetupEditing(
          widthMm: config.widthMm,
          heightMm: config.heightMm,
          cornerRadiusMm: config.cornerRadiusMm,
          paddingTop: paddingTop,
          paddingBottom: paddingBottom,
          paddingLeft: paddingLeft,
          paddingRight: paddingRight,
          isCustomPolygon: isCustom,
          polygonPoints: config.printableArea,
          polygonPointIds: pointIds,
        ));
      } else {
        final pointIds = List.generate(
          4,
          (i) => 'point_${i}_${DateTime.now().microsecondsSinceEpoch}',
        );
        emit(StickerSetupEditing(
          widthMm: 100,
          heightMm: 60,
          cornerRadiusMm: 4,
          paddingTop: 4,
          paddingBottom: 4,
          paddingLeft: 4,
          paddingRight: 4,
          polygonPoints: const [
            StickerPoint(4, 4),
            StickerPoint(96, 4),
            StickerPoint(96, 56),
            StickerPoint(4, 56),
          ],
          polygonPointIds: pointIds,
        ));
      }
    } on Object catch (e) {
      emit(StickerSetupError(e.toString()));
    }
  }

  void updateFields({
    double? widthMm,
    double? heightMm,
    double? cornerRadiusMm,
    double? paddingTop,
    double? paddingBottom,
    double? paddingLeft,
    double? paddingRight,
  }) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final nextWidth = widthMm ?? currentState.widthMm;
    final nextHeight = heightMm ?? currentState.heightMm;
    final nextPaddingLeft = paddingLeft ?? currentState.paddingLeft;
    final nextPaddingTop = paddingTop ?? currentState.paddingTop;
    final nextPaddingRight = paddingRight ?? currentState.paddingRight;
    final nextPaddingBottom = paddingBottom ?? currentState.paddingBottom;

    final List<StickerPoint> points;
    if (!currentState.isCustomPolygon) {
      // Auto-update standard corners
      points = [
        StickerPoint(nextPaddingLeft, nextPaddingTop),
        StickerPoint(nextWidth - nextPaddingRight, nextPaddingTop),
        StickerPoint(nextWidth - nextPaddingRight, nextHeight - nextPaddingBottom),
        StickerPoint(nextPaddingLeft, nextHeight - nextPaddingBottom),
      ];
    } else {
      points = currentState.polygonPoints;
    }

    emit(currentState.copyWith(
      widthMm: widthMm,
      heightMm: heightMm,
      cornerRadiusMm: cornerRadiusMm,
      paddingTop: paddingTop,
      paddingBottom: paddingBottom,
      paddingLeft: paddingLeft,
      paddingRight: paddingRight,
      polygonPoints: points,
    ));
  }

  void toggleCustomPolygon({required bool enabled}) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final List<StickerPoint> points;
    if (enabled) {
      // If turning on, initialize with current rect points
      points = [
        StickerPoint(currentState.paddingLeft, currentState.paddingTop),
        StickerPoint(currentState.widthMm - currentState.paddingRight, currentState.paddingTop),
        StickerPoint(currentState.widthMm - currentState.paddingRight, currentState.heightMm - currentState.paddingBottom),
        StickerPoint(currentState.paddingLeft, currentState.heightMm - currentState.paddingBottom),
      ];
    } else {
      // If turning off, revert to margin-based rectangle
      points = [
        StickerPoint(currentState.paddingLeft, currentState.paddingTop),
        StickerPoint(currentState.widthMm - currentState.paddingRight, currentState.paddingTop),
        StickerPoint(currentState.widthMm - currentState.paddingRight, currentState.heightMm - currentState.paddingBottom),
        StickerPoint(currentState.paddingLeft, currentState.heightMm - currentState.paddingBottom),
      ];
    }

    final pointIds = List.generate(
      points.length,
      (i) => 'point_${i}_${DateTime.now().microsecondsSinceEpoch}',
    );

    emit(currentState.copyWith(
      isCustomPolygon: enabled,
      polygonPoints: points,
      polygonPointIds: pointIds,
    ));
  }

  void updatePolygonPoint(int index, double x, double y) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final list = List<StickerPoint>.from(currentState.polygonPoints);
    if (index >= 0 && index < list.length) {
      list[index] = StickerPoint(x, y);
      emit(currentState.copyWith(polygonPoints: list));
    }
  }

  void addPolygonPoint() {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final list = List<StickerPoint>.from(currentState.polygonPoints);
    final ids = List<String>.from(currentState.polygonPointIds);
    var newX = currentState.widthMm / 2;
    var newY = currentState.heightMm / 2;
    if (list.isNotEmpty) {
      final last = list.last;
      newX = (last.x + 10.0).clamp(0.0, currentState.widthMm);
      newY = (last.y + 10.0).clamp(0.0, currentState.heightMm);
    }
    list.add(StickerPoint(newX, newY));
    ids.add('point_add_${DateTime.now().microsecondsSinceEpoch}');
    emit(currentState.copyWith(polygonPoints: list, polygonPointIds: ids));
  }

  void removePolygonPoint(int index) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final list = List<StickerPoint>.from(currentState.polygonPoints);
    final ids = List<String>.from(currentState.polygonPointIds);
    if (list.length > 3 && index >= 0 && index < list.length) {
      list.removeAt(index);
      ids.removeAt(index);
      emit(currentState.copyWith(polygonPoints: list, polygonPointIds: ids));
    }
  }

  void reorderPolygonPoints(int oldIndex, int newIndex) {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    final list = List<StickerPoint>.from(currentState.polygonPoints);
    final ids = List<String>.from(currentState.polygonPointIds);
    var actualNewIndex = newIndex;
    if (actualNewIndex > oldIndex) {
      actualNewIndex -= 1;
    }
    final item = list.removeAt(oldIndex);
    list.insert(actualNewIndex, item);

    final itemId = ids.removeAt(oldIndex);
    ids.insert(actualNewIndex, itemId);

    emit(currentState.copyWith(
      polygonPoints: list,
      polygonPointIds: ids,
    ));
  }

  Future<void> saveAndContinue() async {
    final currentState = state;
    if (currentState is! StickerSetupEditing) return;

    emit(const StickerSetupSaving());
    try {
      final config = currentState.toConfig();
      await _templateRepository.saveStickerConfig(templateId, config);
      emit(StickerSetupSaved(templateId));
    } on Object catch (e) {
      emit(StickerSetupError(e.toString()));
      emit(currentState);
    }
  }
}
