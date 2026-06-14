import 'dart:convert';
import 'dart:io';
import 'package:stickify/core/services/printing/windows/powershell_scripts.dart';
import 'package:stickify/domain/domain.dart';

/// Validates whether a Windows printer supports a given sheet size config.
class WindowsPaperValidator implements PaperValidationEngine {
  /// Instantiates a new [WindowsPaperValidator].
  WindowsPaperValidator();

  @override
  Future<bool> isPaperSizeSupported(PrinterDevice printer, SheetConfig sheet) async {
    if (!Platform.isWindows) return true;

    try {
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/list_papers.ps1');
      await scriptFile.writeAsString(PowershellScripts.listPapers);

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
        '-PrinterName',
        printer.name,
      ]);

      if (result.exitCode != 0) {
        // Fail-open: if script fails, allow printing to proceed
        return true;
      }

      final dynamic decoded = jsonDecode(result.stdout.toString());
      List<dynamic> papers = [];
      if (decoded is List) {
        papers = decoded;
      } else if (decoded is Map) {
        papers = [decoded];
      }

      final targetW = sheet.pageWidth;
      final targetH = sheet.pageHeight;
      const tolerance = 1.5;

      for (final paper in papers) {
        final w = (paper['Width'] as num?)?.toDouble();
        final h = (paper['Height'] as num?)?.toDouble();
        if (w == null || h == null) continue;

        final normalMatch = (w - targetW).abs() <= tolerance && (h - targetH).abs() <= tolerance;
        final flippedMatch = (w - targetH).abs() <= tolerance && (h - targetW).abs() <= tolerance;

        if (normalMatch || flippedMatch) {
          return true;
        }
      }

      return false;
    } catch (_) {
      // Fail-open
      return true;
    }
  }
}
