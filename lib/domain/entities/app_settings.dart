import 'package:equatable/equatable.dart';

/// Configurable application preferences and print pipeline behavior settings.
class AppSettings extends Equatable {
  /// Creates an [AppSettings] instance.
  const AppSettings({
    this.enableDefaultTemplateUsage = true,
    this.enableResumePartialSheet = true,
    this.printFromBottom = false,
    this.groupBatchVariants = true,
  });

  /// Deserializes a Map into an [AppSettings] instance.
  factory AppSettings.fromMap(Map<String, dynamic> map) {
    return AppSettings(
      enableDefaultTemplateUsage:
          map['enableDefaultTemplateUsage'] as bool? ?? true,
      enableResumePartialSheet:
          map['enableResumePartialSheet'] as bool? ?? true,
      printFromBottom: map['printFromBottom'] as bool? ?? false,
      groupBatchVariants: map['groupBatchVariants'] as bool? ?? true,
    );
  }

  /// Default configuration instance.
  static const AppSettings defaults = AppSettings();

  /// Whether to automatically skip the template selection screen in the
  /// single product print workflow when an assigned default template is present.
  final bool enableDefaultTemplateUsage;

  /// Whether to automatically restore unused label positions from the last
  /// printed partial sheet upon initializing print setup.
  final bool enableResumePartialSheet;

  /// Whether to align sticker label positioning starting from the bottom of the sheet.
  final bool printFromBottom;

  /// Whether to group identical product variants together in batch print workflow
  /// so that labels print continuously.
  final bool groupBatchVariants;

  @override
  List<Object?> get props => [
        enableDefaultTemplateUsage,
        enableResumePartialSheet,
        printFromBottom,
        groupBatchVariants,
      ];

  /// Creates a copy of this [AppSettings] with given fields replaced.
  AppSettings copyWith({
    bool? enableDefaultTemplateUsage,
    bool? enableResumePartialSheet,
    bool? printFromBottom,
    bool? groupBatchVariants,
  }) {
    return AppSettings(
      enableDefaultTemplateUsage:
          enableDefaultTemplateUsage ?? this.enableDefaultTemplateUsage,
      enableResumePartialSheet:
          enableResumePartialSheet ?? this.enableResumePartialSheet,
      printFromBottom: printFromBottom ?? this.printFromBottom,
      groupBatchVariants: groupBatchVariants ?? this.groupBatchVariants,
    );
  }

  /// Converts this [AppSettings] instance into a serializable Map.
  Map<String, dynamic> toMap() {
    return {
      'enableDefaultTemplateUsage': enableDefaultTemplateUsage,
      'enableResumePartialSheet': enableResumePartialSheet,
      'printFromBottom': printFromBottom,
      'groupBatchVariants': groupBatchVariants,
    };
  }
}
