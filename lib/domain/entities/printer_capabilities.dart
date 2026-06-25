import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Represents known hardware or driver limitations and capabilities of a printer.
@immutable
class PrinterCapabilities extends Equatable {
  /// Creates a [PrinterCapabilities] instance.
  const PrinterCapabilities({
    required this.supportsCustomPaperSize,
    required this.supportsPortraitCustomPaper,
    required this.supportsLandscapeCustomPaper,
    required this.supportsManualFeed,
    required this.supportsBorderlessPrinting,
    required this.supportsTraySelection,
    this.nonPrintableMarginLeft = 0.0,
    this.nonPrintableMarginRight = 0.0,
    this.nonPrintableMarginTop = 0.0,
    this.nonPrintableMarginBottom = 0.0,
  });

  /// Whether the printer driver accepts user-defined paper sizes.
  final bool supportsCustomPaperSize;

  /// Whether custom page configurations can be sent in portrait orientation.
  final bool supportsPortraitCustomPaper;

  /// Whether custom page configurations can be sent in landscape orientation.
  final bool supportsLandscapeCustomPaper;

  /// Whether the printer tray supports manual sheet feed.
  final bool supportsManualFeed;

  /// Whether the printer supports borderless/full-bleed edge printing.
  final bool supportsBorderlessPrinting;

  /// Whether the driver supports explicit paper tray selection.
  final bool supportsTraySelection;

  /// The left hardware non-printable margin in millimeters.
  final double nonPrintableMarginLeft;

  /// The right hardware non-printable margin in millimeters.
  final double nonPrintableMarginRight;

  /// The top hardware non-printable margin in millimeters.
  final double nonPrintableMarginTop;

  /// The bottom hardware non-printable margin in millimeters.
  final double nonPrintableMarginBottom;

  @override
  List<Object?> get props => [
        supportsCustomPaperSize,
        supportsPortraitCustomPaper,
        supportsLandscapeCustomPaper,
        supportsManualFeed,
        supportsBorderlessPrinting,
        supportsTraySelection,
        nonPrintableMarginLeft,
        nonPrintableMarginRight,
        nonPrintableMarginTop,
        nonPrintableMarginBottom,
      ];

  @override
  String toString() =>
      'PrinterCapabilities('
      'supportsCustomPaperSize: $supportsCustomPaperSize, '
      'supportsPortraitCustomPaper: $supportsPortraitCustomPaper, '
      'supportsLandscapeCustomPaper: $supportsLandscapeCustomPaper, '
      'supportsManualFeed: $supportsManualFeed, '
      'supportsBorderlessPrinting: $supportsBorderlessPrinting, '
      'supportsTraySelection: $supportsTraySelection, '
      'nonPrintableMarginLeft: $nonPrintableMarginLeft, '
      'nonPrintableMarginRight: $nonPrintableMarginRight, '
      'nonPrintableMarginTop: $nonPrintableMarginTop, '
      'nonPrintableMarginBottom: $nonPrintableMarginBottom)';
}
