// Redundant argument values are used in tests to verify serialization handling of defaults.
// ignore_for_file: avoid_redundant_argument_values
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/data/models/firestore/printer_profile_firestore_model.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrinterProfileFirestoreModel Tests', () {
    final now = DateTime(2026, 6, 24, 12, 0, 0);

    final profile = PrinterProfile(
      id: 'prof-test-123',
      displayName: 'Zebra Shipping Profile',
      status: PrinterProfileStatus.active,
      printerIdentity: const PrinterIdentity(
        systemPrinterName: 'Zebra ZT411',
        manufacturer: 'Zebra Technologies',
        model: 'ZT411 203dpi',
        driverName: 'Zebra Designer v8',
        driverVersion: '8.6.0.0',
      ),
      capabilities: const PrinterCapabilities(
        supportsCustomPaperSize: true,
        supportsPortraitCustomPaper: true,
        supportsLandscapeCustomPaper: false,
        supportsManualFeed: false,
        supportsBorderlessPrinting: false,
        supportsTraySelection: true,
      ),
      optimizationPreferences: const OptimizationPreferences(
        allowScaling: true,
        allowTranslation: true,
        preferShrinkOverShift: false,
        allowStickerSpecificAdjustment: true,
      ),
      trays: [
        PrinterTrayProfile(
          trayIdentifier: 'tray_1',
          displayName: 'Main Roll Feed',
          supportedPaperConfigurations: const [
            PaperConfigurationReference(
              id: 'shipping_100x150',
              displayName: 'Shipping Label 100x150',
            ),
          ],
          calibration: PrinterCalibration(
            enabled: true,
            calibrationRules: const [
              CalibrationRule(
                target: CalibrationTarget.sheet(),
                transformation: PrintStickerTransform(
                  offsetX: 1.5,
                  offsetY: -2,
                  scaleX: 0.98,
                  scaleY: 0.98,
                  anchorX: 0,
                  anchorY: 1,
                ),
              ),
              CalibrationRule(
                target: CalibrationTarget.edge(EdgeGroup.left),
                transformation: PrintStickerTransform(
                  offsetX: -0.5,
                  offsetY: 0,
                  scaleX: 1,
                  scaleY: 1,
                  anchorX: 0.5,
                  anchorY: 0.5,
                ),
              ),
            ],
            lastCalibratedAt: now,
          ),
        ),
      ],
      createdAt: now,
      updatedAt: now,
      lastValidatedAt: now,
    );

    test(
      'round-trip serialization toDomain and fromDomain preserves nested calibration values',
      () {
        final firestoreModel = PrinterProfileFirestoreModel.fromDomain(profile);
        final domain = firestoreModel.toDomain();

        expect(domain.id, equals(profile.id));
        expect(domain.displayName, equals(profile.displayName));
        expect(domain.status, equals(profile.status));
        expect(domain.printerIdentity, equals(profile.printerIdentity));
        expect(domain.capabilities, equals(profile.capabilities));
        expect(
          domain.optimizationPreferences,
          equals(profile.optimizationPreferences),
        );
        expect(domain.trays, equals(profile.trays));
        expect(domain.createdAt, equals(profile.createdAt));
        expect(domain.updatedAt, equals(profile.updatedAt));
        expect(domain.lastValidatedAt, equals(profile.lastValidatedAt));

        final firstTray = domain.trays.first;
        expect(firstTray.trayIdentifier, equals('tray_1'));
        expect(
          firstTray.supportedPaperConfigurations.first.id,
          equals('shipping_100x150'),
        );
        expect(firstTray.calibration.enabled, isTrue);
        expect(firstTray.calibration.calibrationRules.length, equals(2));
        expect(
          firstTray.calibration.calibrationRules.first.target.type,
          equals(TargetType.sheet),
        );
        expect(
          firstTray.calibration.calibrationRules.first.transformation.offsetX,
          equals(1.5),
        );
      },
    );

    test('toMap and fromMap correct serialization and deserialization', () {
      final firestoreModel = PrinterProfileFirestoreModel.fromDomain(profile);
      final map = firestoreModel.toMap();

      expect(map['id'], equals('prof-test-123'));
      expect(map['displayName'], equals('Zebra Shipping Profile'));
      expect(map['status'], equals('active'));
      expect(map['createdAt'], isA<Timestamp>());

      final fromMapModel =
          PrinterProfileFirestoreModel.fromMap('prof-test-123', map);
      final mappedDomain = fromMapModel.toDomain();

      expect(mappedDomain, equals(profile));
    });
  });
}
