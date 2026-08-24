import 'dart:async';

import 'package:stickify/domain/domain.dart';

/// Local storage implementation of [SettingsRepository] backed by [LocalDatabase].
class DatabaseSettingsRepository implements SettingsRepository {
  /// Creates a [DatabaseSettingsRepository] instance.
  DatabaseSettingsRepository({required LocalDatabase database})
      : _db = database;

  final LocalDatabase _db;
  static const String _collection = 'settings';

  static const String _keyDefaultTemplate = 'enable_default_template_usage';
  static const String _keyResumePartialSheet = 'enable_resume_partial_sheet';
  static const String _keyPrintFromBottom = 'print_from_bottom';
  static const String _keyGroupBatchVariants = 'group_batch_variants';
  static const String _keyPerSheetSpooling = 'enable_per_sheet_spooling';

  final StreamController<AppSettings> _settingsController =
      StreamController<AppSettings>.broadcast();

  @override
  Stream<AppSettings> get watchSettings => _settingsController.stream;

  @override
  Future<AppSettings> getSettings() async {
    try {
      final enableDefaultTemplate =
          await _db.get<bool>(_collection, _keyDefaultTemplate) ?? true;
      final enableResumePartial =
          await _db.get<bool>(_collection, _keyResumePartialSheet) ?? true;
      final printFromBottom =
          await _db.get<bool>(_collection, _keyPrintFromBottom) ?? false;
      final groupBatchVariants =
          await _db.get<bool>(_collection, _keyGroupBatchVariants) ?? true;
      final enablePerSheetSpooling =
          await _db.get<bool>(_collection, _keyPerSheetSpooling) ?? false;

      return AppSettings(
        enableDefaultTemplateUsage: enableDefaultTemplate,
        enableResumePartialSheet: enableResumePartial,
        printFromBottom: printFromBottom,
        groupBatchVariants: groupBatchVariants,
        enablePerSheetSpooling: enablePerSheetSpooling,
      );
    } catch (_) {
      return AppSettings.defaults;
    }
  }

  @override
  Future<void> saveSettings(AppSettings settings) async {
    try {
      await _db.save<bool>(
        _collection,
        _keyDefaultTemplate,
        settings.enableDefaultTemplateUsage,
      );
      await _db.save<bool>(
        _collection,
        _keyResumePartialSheet,
        settings.enableResumePartialSheet,
      );
      await _db.save<bool>(
        _collection,
        _keyPrintFromBottom,
        settings.printFromBottom,
      );
      await _db.save<bool>(
        _collection,
        _keyGroupBatchVariants,
        settings.groupBatchVariants,
      );
      await _db.save<bool>(
        _collection,
        _keyPerSheetSpooling,
        settings.enablePerSheetSpooling,
      );
      _settingsController.add(settings);
    } catch (_) {}
  }
}
