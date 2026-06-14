import 'dart:async';
import 'dart:io';
import 'package:stickify/core/services/printing/windows/powershell_scripts.dart';
import 'package:stickify/domain/domain.dart';

/// Manages the Windows DEVMODE configuration lifecycle.
///
/// Ensures custom paper dimensions are set before printing and restored afterwards.
///
/// ## Concurrency safety
///
/// [applySettings] and [restoreSettings] must execute sequentially — the
/// registry must be fully restored before the next job begins. This is
/// enforced via a **Completer chain mutex**:
///
/// Each new caller captures the current pending future synchronously, then
/// creates its own [Completer] and assigns its future as the new pending tail
/// **before** yielding the event loop. The captured future is then awaited,
/// ensuring strict FIFO ordering with no race condition between observation
/// and assignment.
///
/// This pattern is safe in a single Dart isolate because the chain is built
/// within a single synchronous execution frame before any `await`.
///
/// ```dart
/// Job A starts  →  chain: [A]
/// Job B arrives →  chain: [A] → [B]   (B awaits A's future)
/// Job A finishes → A.complete()       (B is now released)
/// Job B runs    → chain: [B]
/// ```
class WindowsDevModeManager {
  /// Instantiates a new [WindowsDevModeManager].
  WindowsDevModeManager();

  /// The tail of the Completer chain.
  ///
  /// Always holds the future of the most recently started job. New callers
  /// capture and await this before beginning work, then assign their own
  /// future as the new tail.
  Future<void> _pendingJob = Future.value();

  /// The [Completer] for the currently active job, set by [applySettings]
  /// and completed by [restoreSettings].
  Completer<void>? _currentJobCompleter;

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
  ///
  /// Waits for any in-progress job to complete before modifying the registry.
  /// Returns a backup token string that must be passed to [restoreSettings].
  /// Returns `null` if the platform is not Windows or if the script fails.
  Future<String?> applySettings(PrinterDevice printer, SheetConfig sheet) async {
    if (!Platform.isWindows) return null;

    // Build the chain synchronously before any await.
    // Capturing 'previous' and assigning the new tail happens in one
    // synchronous frame — no yield point between these two lines.
    final previous = _pendingJob;
    final thisJob = Completer<void>();
    _pendingJob = thisJob.future;
    _currentJobCompleter = thisJob;

    // Wait for the previous job to fully complete (apply + restore).
    await previous;

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
        final match = RegExp('BACKUP:(.*)').firstMatch(output);
        if (match != null) {
          return match.group(1)?.trim();
        }
      }
    } catch (_) {
      // On failure release the lock immediately — restoreSettings will not
      // be called when applySettings returns null.
      _releaseCurrentJob();
    }

    // No backup token obtained — release the lock.
    _releaseCurrentJob();
    return null;
  }

  /// Restores original DEVMODE settings back to the printer in the registry.
  ///
  /// Must always be called after a successful [applySettings] call, regardless
  /// of whether printing succeeded or failed. Completing this call releases the
  /// mutex and allows the next queued job to proceed.
  Future<void> restoreSettings(PrinterDevice printer, String backupToken) async {
    if (!Platform.isWindows) {
      _releaseCurrentJob();
      return;
    }

    try {
      // Delay restoring registry to allow the spooler to fully process/lock print job settings
      await Future<void>.delayed(const Duration(seconds: 5));

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
      // Fallback — still release lock below
    } finally {
      _releaseCurrentJob();
    }
  }

  /// Completes the current job's [Completer], releasing the mutex for the next
  /// queued caller.
  void _releaseCurrentJob() {
    final completer = _currentJobCompleter;
    _currentJobCompleter = null;
    if (completer != null && !completer.isCompleted) {
      completer.complete();
    }
  }
}
