import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('AppSettings Entity Tests', () {
    test('defaults has expected initial values', () {
      const settings = AppSettings.defaults;
      expect(settings.enableDefaultTemplateUsage, isTrue);
      expect(settings.enableResumePartialSheet, isTrue);
      expect(settings.printFromBottom, isFalse);
      expect(settings.groupBatchVariants, isTrue);
    });

    test('copyWith updates specified fields correctly', () {
      final updated = AppSettings.defaults.copyWith(
        enableDefaultTemplateUsage: false,
        enableResumePartialSheet: false,
        printFromBottom: true,
        groupBatchVariants: false,
      );

      expect(updated.enableDefaultTemplateUsage, isFalse);
      expect(updated.enableResumePartialSheet, isFalse);
      expect(updated.printFromBottom, isTrue);
      expect(updated.groupBatchVariants, isFalse);
    });

    test('toMap and fromMap serialize and deserialize correctly', () {
      const settings = AppSettings(
        enableDefaultTemplateUsage: false,
        printFromBottom: true,
      );

      final map = settings.toMap();
      final deserialized = AppSettings.fromMap(map);

      expect(deserialized, equals(settings));
    });

    test('props equality works as expected', () {
      const s1 = AppSettings.defaults;
      const s2 = AppSettings.defaults;
      const s3 = AppSettings(enableDefaultTemplateUsage: false);

      expect(s1, equals(s2));
      expect(s1, isNot(equals(s3)));
    });
  });
}
