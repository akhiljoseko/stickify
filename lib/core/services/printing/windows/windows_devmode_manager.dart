import 'dart:async';
import 'dart:io';
import 'package:stickify/core/services/printing/windows/powershell_scripts.dart';
import 'package:stickify/domain/domain.dart';

/// Manages the Windows DEVMODE configuration lifecycle.
///
/// Ensures custom paper dimensions are set before printing and restored afterwards.
class WindowsDevModeManager {
  /// Instantiates a new [WindowsDevModeManager].
  WindowsDevModeManager();

  Completer<void>? _activeJobCompleter;

  /// Restores any leftover DEVMODE registry backups on startup.
  Future<void> healOnStartup() async {
    if (!Platform.isWindows) return;
    try {
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/heal_devmode.ps1');
      await scriptFile.writeAsString(PowershellScripts.healRegistry);

      await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
      ]);
    } catch (_) {
      // Fail silently
    }
  }

  /// Sets temporary DEVMODE custom page dimensions for the selected printer.
  Future<String?> applySettings(PrinterDevice printer, SheetConfig sheet) async {
    if (!Platform.isWindows) return null;

    // Mutex queue: wait for any active job to finish
    while (_activeJobCompleter != null) {
      await _activeJobCompleter!.future;
    }
    _activeJobCompleter = Completer<void>();

    try {
      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/devmode_settings.ps1');
      await scriptFile.writeAsString(PowershellScripts.devMode);

      final result = await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
        '-Action',
        'set',
        '-PrinterName',
        printer.name,
        '-WidthMm',
        sheet.pageWidth.toString(),
        '-HeightMm',
        sheet.pageHeight.toString(),
      ]);

      if (result.exitCode == 0) {
        final output = result.stdout.toString().trim();
        final match = RegExp(r'BACKUP:(.*)').firstMatch(output);
        if (match != null) {
          return match.group(1)?.trim();
        }
      }
    } catch (_) {
      // Fallback
    }
    return null;
  }

  /// Restores original DEVMODE settings back to the printer in the registry.
  Future<void> restoreSettings(PrinterDevice printer, String backupToken) async {
    if (!Platform.isWindows) {
      final completer = _activeJobCompleter;
      _activeJobCompleter = null;
      completer?.complete();
      return;
    }

    try {
      // Delay restoring registry to allow the spooler to fully process/lock print job settings
      await Future.delayed(const Duration(seconds: 5));

      final tempDir = Directory.systemTemp;
      final scriptFile = File('${tempDir.path}/devmode_settings.ps1');
      await scriptFile.writeAsString(PowershellScripts.devMode);

      await Process.run('powershell', [
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptFile.path,
        '-Action',
        'restore',
        '-PrinterName',
        printer.name,
        '-BackupBase64',
        backupToken,
      ]);
    } catch (_) {
      // Fallback
    } finally {
      final completer = _activeJobCompleter;
      _activeJobCompleter = null;
      completer?.complete();
    }
  }
}
