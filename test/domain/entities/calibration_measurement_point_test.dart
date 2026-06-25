import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationMeasurementPoint', () {
    test('succeeds on valid construction', () {
      final point = CalibrationMeasurementPoint(
        id: 'point_1',
        label: 'TL',
        expectedX: 10,
        expectedY: 15,
      );
      expect(point.id, 'point_1');
      expect(point.label, 'TL');
      expect(point.expectedX, 10);
      expect(point.expectedY, 15);
    });

    test('throws AssertionError when id is empty', () {
      expect(
        () => CalibrationMeasurementPoint(
          id: '',
          label: 'TL',
          expectedX: 10,
          expectedY: 15,
        ),
        throwsAssertionError,
      );
    });

    test('throws AssertionError when label is empty', () {
      expect(
        () => CalibrationMeasurementPoint(
          id: 'point_1',
          label: '',
          expectedX: 10,
          expectedY: 15,
        ),
        throwsAssertionError,
      );
    });

    test('supports Equatable equality', () {
      final pointA = CalibrationMeasurementPoint(
        id: 'point_1',
        label: 'TL',
        expectedX: 10,
        expectedY: 15,
      );
      final pointB = CalibrationMeasurementPoint(
        id: 'point_1',
        label: 'TL',
        expectedX: 10,
        expectedY: 15,
      );
      final pointC = CalibrationMeasurementPoint(
        id: 'point_2',
        label: 'TR',
        expectedX: 10,
        expectedY: 15,
      );

      expect(pointA, pointB);
      expect(pointA, isNot(pointC));
    });
  });
}
