import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('CalibrationMeasurement', () {
    final point = CalibrationMeasurementPoint(
      id: 'point_1',
      label: 'TL',
      expectedX: 10,
      expectedY: 15,
    );

    test('computes positive deltas correctly', () {
      final measurement = CalibrationMeasurement(
        point: point,
        actualX: 12,
        actualY: 18.5,
      );
      expect(measurement.point, point);
      expect(measurement.actualX, 12);
      expect(measurement.actualY, 18.5);
      expect(measurement.deltaX, 2);
      expect(measurement.deltaY, 3.5);
    });

    test('computes negative deltas correctly', () {
      final measurement = CalibrationMeasurement(
        point: point,
        actualX: 7.5,
        actualY: 11,
      );
      expect(measurement.deltaX, -2.5);
      expect(measurement.deltaY, -4);
    });

    test('computes zero deltas correctly', () {
      final measurement = CalibrationMeasurement(
        point: point,
        actualX: 10,
        actualY: 15,
      );
      expect(measurement.deltaX, 0);
      expect(measurement.deltaY, 0);
    });

    test('supports Equatable equality', () {
      final measurementA = CalibrationMeasurement(
        point: point,
        actualX: 10,
        actualY: 15,
      );
      final measurementB = CalibrationMeasurement(
        point: point,
        actualX: 10,
        actualY: 15,
      );
      final measurementC = CalibrationMeasurement(
        point: point,
        actualX: 11,
        actualY: 15,
      );

      expect(measurementA, measurementB);
      expect(measurementA, isNot(measurementC));
    });
  });
}
