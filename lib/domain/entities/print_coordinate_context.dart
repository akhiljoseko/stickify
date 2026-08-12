import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents an affine coordinate transformation applied to a single sticker
/// slot position during PDF rendering.
///
/// All offsets are in millimeters. All scale factors are dimensionless
/// multipliers (1.0 = no change).
///
/// The default [PrintStickerTransform.identity] constructor produces a no-op transformation.
@immutable
class PrintStickerTransform extends Equatable {
  /// Creates a [PrintStickerTransform] with the given offsets, scale factors,
  /// and normalized scaling anchor ratios.
  const PrintStickerTransform({
    this.offsetX = 0.0,
    this.offsetY = 0.0,
    this.scaleX = 1.0,
    this.scaleY = 1.0,
    this.anchorX = 0.5,
    this.anchorY = 0.5,
  })  : assert(
          anchorX >= 0.0 && anchorX <= 1.0,
          'anchorX must be between 0.0 and 1.0',
        ),
        assert(
          anchorY >= 0.0 && anchorY <= 1.0,
          'anchorY must be between 0.0 and 1.0',
        );

  /// Creates an identity [PrintStickerTransform] that applies no change.
  const PrintStickerTransform.identity()
      : offsetX = 0.0,
        offsetY = 0.0,
        scaleX = 1.0,
        scaleY = 1.0,
        anchorX = 0.5,
        anchorY = 0.5;

  /// Horizontal offset applied to the sticker's X position, in millimeters.
  final double offsetX;

  /// Vertical offset applied to the sticker's Y position, in millimeters.
  final double offsetY;

  /// Scale factor applied to the sticker's width (1.0 = no change).
  final double scaleX;

  /// Scale factor applied to the sticker's height (1.0 = no change).
  final double scaleY;

  /// Horizontal normalized scaling anchor ratio (0.0 = left, 0.5 = center, 1.0 = right).
  final double anchorX;

  /// Vertical normalized scaling anchor ratio (0.0 = top, 0.5 = center, 1.0 = bottom).
  final double anchorY;

  /// Returns `true` if this transform has no effect on coordinates or dimensions.
  bool get isIdentity =>
      offsetX == 0.0 && offsetY == 0.0 && scaleX == 1.0 && scaleY == 1.0;

  @override
  List<Object?> get props => [offsetX, offsetY, scaleX, scaleY, anchorX, anchorY];

  @override
  String toString() =>
      'PrintStickerTransform(offsetX: $offsetX, offsetY: $offsetY, '
      'scaleX: $scaleX, scaleY: $scaleY, anchorX: $anchorX, anchorY: $anchorY)';
}

/// Carries all coordinate transformation information for a single print job.
///
/// This object is designed for future extensibility. The initial resolution strategy
/// for computing the effective transform for a sticker slot checks lookups in order of specificity:
///
/// ```dart
/// stickerTransforms  (most specific — per absolute slot index)
///       |
/// columnTransforms   (per column index)
///       |
/// rowTransforms      (per row index)
///       |
/// globalTransform    (least specific — applies to the whole sheet)
/// ```
///
/// The default [PrintCoordinateContext.identity] constructor produces a context that applies no
/// transformation to any sticker slot, preserving the current print behavior
/// exactly.
///
/// ## Future Extensibility & Composition
///
/// New transformation categories (e.g. edge-group transforms) can be added as
/// new fields on this class. The [resolveFor] method is the single location
/// where transform lookup logic lives. While the current implementation checks
/// specific overrides in sequence, future versions may compose these
/// transformations (e.g. composing translations and scale factors across global,
/// row, column, and slot levels).
@immutable
class PrintCoordinateContext extends Equatable {
  /// Creates a [PrintCoordinateContext] with the given transformations.
  ///
  /// Any omitted map defaults to empty (no override for that category).
  /// The [globalTransform] defaults to [PrintStickerTransform.identity].
  const PrintCoordinateContext({
    this.globalTransform = const PrintStickerTransform.identity(),
    this.rowTransforms = const {},
    this.columnTransforms = const {},
    this.stickerTransforms = const {},
  });

  /// Creates an identity [PrintCoordinateContext] that applies no
  /// transformation to any sticker slot.
  ///
  /// Use this as the default when no printer calibration or optimization is
  /// active. The PDF output will be byte-equivalent to the pre-1A behavior.
  const PrintCoordinateContext.identity() : this();

  /// Transformation applied to every sticker on the sheet when no
  /// more-specific override exists.
  ///
  /// Defaults to [PrintStickerTransform.identity] (no change).
  final PrintStickerTransform globalTransform;

  /// Per-row transformation overrides.
  ///
  /// Key: zero-based row index. Value: the transform to apply to every sticker
  /// in that row. Takes precedence over [globalTransform].
  final Map<int, PrintStickerTransform> rowTransforms;

  /// Per-column transformation overrides.
  ///
  /// Key: zero-based column index. Value: the transform to apply to every
  /// sticker in that column. Takes precedence over [rowTransforms] and
  /// [globalTransform].
  final Map<int, PrintStickerTransform> columnTransforms;

  /// Per-sticker transformation overrides.
  ///
  /// Key: absolute slot index (across all sheets). Value: the transform to
  /// apply to that specific sticker only. Highest priority — takes precedence
  /// over all other transforms.
  final Map<int, PrintStickerTransform> stickerTransforms;

  /// Resolves the effective [PrintStickerTransform] for the sticker at the
  /// given [row], [column], and [absoluteSlotIndex].
  ///
  /// The lookup strategy returns the most specific override available
  /// (highest to lowest specificity):
  /// 1. [stickerTransforms] keyed by [absoluteSlotIndex] (job-wide absolute slot override)
  /// 2. [stickerTransforms] keyed by `absoluteSlotIndex % slotsPerSheet` (per-sheet grid slot override)
  /// 3. [columnTransforms]  keyed by [column]
  /// 4. [rowTransforms]     keyed by [row]
  /// 5. [globalTransform]
  PrintStickerTransform resolveFor({
    required int row,
    required int column,
    required int absoluteSlotIndex,
    int? slotsPerSheet,
  }) {
    final stickerOverride = stickerTransforms[absoluteSlotIndex];
    if (stickerOverride != null) return stickerOverride;

    if (slotsPerSheet != null && slotsPerSheet > 0) {
      final sheetSlotIndex = absoluteSlotIndex % slotsPerSheet;
      final sheetStickerOverride = stickerTransforms[sheetSlotIndex];
      if (sheetStickerOverride != null) return sheetStickerOverride;
    }

    final columnOverride = columnTransforms[column];
    if (columnOverride != null) return columnOverride;

    final rowOverride = rowTransforms[row];
    if (rowOverride != null) return rowOverride;

    return globalTransform;
  }

  /// Returns `true` if this context applies no transformation to any sticker.
  bool get isIdentity =>
      globalTransform.isIdentity &&
      rowTransforms.isEmpty &&
      columnTransforms.isEmpty &&
      stickerTransforms.isEmpty;

  @override
  List<Object?> get props =>
      [globalTransform, rowTransforms, columnTransforms, stickerTransforms];

  @override
  String toString() =>
      'PrintCoordinateContext('
      'globalTransform: $globalTransform, '
      'rows: ${rowTransforms.length}, '
      'columns: ${columnTransforms.length}, '
      'stickers: ${stickerTransforms.length})';
}
