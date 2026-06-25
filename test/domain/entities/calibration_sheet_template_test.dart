import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationSheetTemplate', () {
    final point1 = CalibrationMeasurementPoint(
      id: 'p1',
      label: 'TL',
      expectedX: 10,
      expectedY: 15,
    );
    final point2 = CalibrationMeasurementPoint(
      id: 'p2',
      label: 'TR',
      expectedX: 100,
      expectedY: 15,
    );

    test('succeeds on valid construction', () {
      final template = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: [point1, point2],
        pageWidth: 210,
        pageHeight: 297,
      );
      expect(template.id, 'temp_1');
      expect(template.name, 'Template 1');
      expect(template.points, [point1, point2]);
      expect(template.pageWidth, 210);
      expect(template.pageHeight, 297);
    });

    test('has default page dimensions when omitted', () {
      final template = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: [point1, point2],
      );
      expect(template.pageWidth, 210.0);
      expect(template.pageHeight, 297.0);
    });

    test('throws AssertionError when pageWidth is non-positive', () {
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: 'Template 1',
          points: [point1],
          pageWidth: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: 'Template 1',
          points: [point1],
          pageWidth: -5,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when pageHeight is non-positive', () {
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: 'Template 1',
          points: [point1],
          pageHeight: 0,
        ),
        throwsAssertionError,
      );
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: 'Template 1',
          points: [point1],
          pageHeight: -100,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when id is empty', () {
      expect(
        () => CalibrationSheetTemplate(
          id: '',
          name: 'Template 1',
          points: [point1],
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when name is empty', () {
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: '',
          points: [point1],
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when points list is empty', () {
      expect(
        () => CalibrationSheetTemplate(
          id: 'temp_1',
          name: 'Template 1',
          points: const [],
        ),
        throwsAssertionError,
      );
    });

    test('verifies defensive copying and immutability', () {
      final originalList = [point1];
      final template = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: originalList,
      );

      // Verify defensive copy: original modification doesn't affect template
      originalList.add(point2);
      expect(template.points.length, 1);
      expect(template.points, contains(point1));
      expect(template.points, isNot(contains(point2)));

      // Verify template points list itself throws UnsupportedError on mutation
      expect(
        () => template.points.add(point2),
        throwsUnsupportedError,
      );
      expect(
        template.points.clear,
        throwsUnsupportedError,
      );
    });

    test('supports Equatable equality', () {
      final templateA = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: [point1, point2],
      );
      final templateB = CalibrationSheetTemplate(
        id: 'temp_1',
        name: 'Template 1',
        points: [point1, point2],
      );
      final templateC = CalibrationSheetTemplate(
        id: 'temp_2',
        name: 'Template 1',
        points: [point1],
      );

      expect(templateA, templateB);
      expect(templateA, isNot(templateC));
    });
  });
}
