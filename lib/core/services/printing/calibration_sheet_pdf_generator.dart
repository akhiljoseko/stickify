import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:stickify/domain/domain.dart';

/// Service responsible for generating the calibration sheet PDF used by technicians.
class CalibrationSheetPdfGenerator {
  /// Creates a [CalibrationSheetPdfGenerator] instance.
  const CalibrationSheetPdfGenerator();

  /// Generates the raw PDF bytes for a [CalibrationSheetTemplate].
  Future<Uint8List> generatePdfBytes({
    required CalibrationSheetTemplate template,
    required String printerName,
    required String trayName,
    DateTime? timestamp,
  }) async {
    final doc = pw.Document();
    final time = timestamp ?? DateTime.now();

    final widthPt = template.pageWidth * PdfPageFormat.mm;
    final heightPt = template.pageHeight * PdfPageFormat.mm;
    final pageFormat = PdfPageFormat(widthPt, heightPt, marginAll: 0);

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          final canvas = context.canvas;

          // 1. Draw 12mm wide coloured bands at each paper edge as a visual
          //    reference for the non-printable margin zone. Most printers cannot
          //    place toner/ink within this region. The red calibration crosshairs
          //    at 20mm offset are unaffected.
          const bandWidth = 12.0 * PdfPageFormat.mm;
          const bandColor = 0xFFE0E0E0;
          canvas
            ..setFillColor(const PdfColor.fromInt(bandColor))
            ..drawRect(0, 0, widthPt, bandWidth) // top band
            ..drawRect(0, heightPt - bandWidth, widthPt, bandWidth) // bottom
            ..drawRect(0, 0, bandWidth, heightPt) // left band
            ..drawRect(widthPt - bandWidth, 0, bandWidth, heightPt) // right
            ..fillPath();

          // 2. Draw Registration Marks at four corners (10mm offset, 8mm line length)
          const regOffset = 10.0 * PdfPageFormat.mm;
          const regLen = 8.0 * PdfPageFormat.mm;
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(1);

          void drawRegMark(double cx, double cy) {
            canvas
              ..drawEllipse(
                cx,
                cy,
                3.0 * PdfPageFormat.mm,
                3.0 * PdfPageFormat.mm,
              )
              ..moveTo(cx - regLen, cy)
              ..lineTo(cx + regLen, cy)
              ..moveTo(cx, cy - regLen)
              ..lineTo(cx, cy + regLen)
              ..strokePath();
          }

          // Top-Left (Origin at bottom-left in PDF canvas, so top is heightPt)
          drawRegMark(regOffset, heightPt - regOffset);
          // Top-Right
          drawRegMark(widthPt - regOffset, heightPt - regOffset);
          // Bottom-Left
          drawRegMark(regOffset, regOffset);
          // Bottom-Right
          drawRegMark(widthPt - regOffset, regOffset);

          // 3. Draw Ruler Scale along Top and Left edges
          canvas
            ..setStrokeColor(PdfColors.black)
            ..setLineWidth(0.5);

          // Top Edge Ruler
          final topY = heightPt;
          for (double x = 0; x <= template.pageWidth; x += 5) {
            final xPt = x * PdfPageFormat.mm;
            final isMajor = x % 10 == 0;
            final tickLen = (isMajor ? 6.0 : 3.0) * PdfPageFormat.mm;

            canvas
              ..moveTo(xPt, topY)
              ..lineTo(xPt, topY - tickLen)
              ..strokePath();
          }

          // Left Edge Ruler (measured from top down)
          for (double y = 0; y <= template.pageHeight; y += 5) {
            final yPt = heightPt - y * PdfPageFormat.mm;
            final isMajor = y % 10 == 0;
            final tickLen = (isMajor ? 6.0 : 3.0) * PdfPageFormat.mm;

            canvas
              ..moveTo(0, yPt)
              ..lineTo(tickLen, yPt)
              ..strokePath();
          }

          // 4. Draw Target Crosshairs at each calibration point
          for (final point in template.points) {
            final cx = point.expectedX * PdfPageFormat.mm;
            final cy = heightPt - (point.expectedY * PdfPageFormat.mm);
            const crossLen = 6.0 * PdfPageFormat.mm;

            canvas
              ..setStrokeColor(PdfColors.red)
              ..setLineWidth(0.75)
              ..moveTo(cx - crossLen, cy)
              ..lineTo(cx + crossLen, cy)
              ..moveTo(cx, cy - crossLen)
              ..lineTo(cx, cy + crossLen)
              ..drawEllipse(
                cx,
                cy,
                1.5 * PdfPageFormat.mm,
                1.5 * PdfPageFormat.mm,
              )
              ..strokePath();
          }

          // 5. Text elements (Ruler numbers, point labels, metadata footer)
          return pw.Stack(
            children: [
              // Top Ruler numbers (labeled every 10 mm)
              ...List.generate((template.pageWidth / 10).floor() + 1, (i) {
                final x = i * 10;
                final xPt = x * PdfPageFormat.mm;
                if (xPt > widthPt - 15) return pw.Container();
                return pw.Positioned(
                  left: xPt - 5,
                  top: 8,
                  child: pw.Text(
                    '$x',
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.black,
                    ),
                  ),
                );
              }),

              // Left Ruler numbers (labeled every 10 mm, measured from top)
              ...List.generate((template.pageHeight / 10).floor() + 1, (i) {
                final y = i * 10;
                final yPt = y * PdfPageFormat.mm;
                if (yPt > heightPt - 15) return pw.Container();
                return pw.Positioned(
                  left: 8,
                  top: yPt - 4,
                  child: pw.Text(
                    '$y',
                    style: const pw.TextStyle(
                      fontSize: 6,
                      color: PdfColors.black,
                    ),
                  ),
                );
              }),

              // Calibration Point Labels
              ...template.points.map((point) {
                final cx = point.expectedX * PdfPageFormat.mm;
                final cy = point.expectedY * PdfPageFormat.mm;
                return pw.Positioned(
                  left: cx + 4.0,
                  top: cy + 4.0,
                  child: pw.Text(
                    point.label,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColors.red,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                );
              }),

              // Footer Metadata
              pw.Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: pw.Center(
                  child: pw.Text(
                    'Printer: $printerName  |  Tray: $trayName  |  Sheet: ${template.name}  |  Generated: ${time.toIso8601String()}',
                    style: const pw.TextStyle(
                      fontSize: 7,
                      color: PdfColors.grey700,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }
}
