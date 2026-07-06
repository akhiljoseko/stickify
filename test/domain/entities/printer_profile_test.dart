// Ignore redundant argument values because tests explicitly verify that passing
// default/neutral values behaves correctly and compiles.
// ignore_for_file: avoid_redundant_argument_values
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('PrinterIdentity Validation & Equality Tests', () {
    test('enforces systemPrinterName is not empty', () {
      expect(
        () => PrinterIdentity(systemPrinterName: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('allows other metadata fields to be empty strings', () {
      const identity = PrinterIdentity(
        systemPrinterName: 'Zebra ZT411',
        manufacturer: '',
        model: '',
        driverName: '',
        driverVersion: '',
      );
      expect(identity.systemPrinterName, equals('Zebra ZT411'));
      expect(identity.manufacturer, isEmpty);
      expect(identity.model, isEmpty);
      expect(identity.driverName, isEmpty);
      expect(identity.driverVersion, isEmpty);
    });

    test('supports Equatable value equality', () {
      const id1 = PrinterIdentity(
        systemPrinterName: 'Zebra ZT411',
        manufacturer: 'Zebra',
        model: 'ZT411',
        driverName: 'Zebra PCL6',
        driverVersion: '1.2.3',
      );
      const id2 = PrinterIdentity(
        systemPrinterName: 'Zebra ZT411',
        manufacturer: 'Zebra',
        model: 'ZT411',
        driverName: 'Zebra PCL6',
        driverVersion: '1.2.3',
      );
      const id3 = PrinterIdentity(
        systemPrinterName: 'Zebra ZT411',
        manufacturer: 'Generic',
        model: 'ZT411',
        driverName: 'Zebra PCL6',
        driverVersion: '1.2.3',
      );

      expect(id1, equals(id2));
      expect(id1, isNot(equals(id3)));
    });
  });

  group('PaperConfigurationReference Validation & Equality Tests', () {
    test('enforces non-empty id and displayName', () {
      expect(
        () => PaperConfigurationReference(id: '', displayName: 'Label'),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PaperConfigurationReference(id: 'label_id', displayName: ''),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports Equatable value equality', () {
      const ref1 = PaperConfigurationReference(
        id: 'shipping_100x150',
        displayName: 'Shipping Label',
      );
      const ref2 = PaperConfigurationReference(
        id: 'shipping_100x150',
        displayName: 'Shipping Label',
      );
      const ref3 = PaperConfigurationReference(
        id: 'shipping_100x150',
        displayName: 'Different Label',
      );

      expect(ref1, equals(ref2));
      expect(ref1, isNot(equals(ref3)));
    });
  });

  group('CalibrationTarget Invariants & Validation Tests', () {
    test('valid target constructions succeed', () {
      const targetSheet = CalibrationTarget.sheet();
      expect(targetSheet.type, equals(TargetType.sheet));
      expect(targetSheet.index, isNull);
      expect(targetSheet.edgeGroup, isNull);

      const targetRow = CalibrationTarget.row(3);
      expect(targetRow.type, equals(TargetType.row));
      expect(targetRow.index, equals(3));

      const targetCol = CalibrationTarget.column(0);
      expect(targetCol.type, equals(TargetType.column));
      expect(targetCol.index, equals(0));

      const targetSticker = CalibrationTarget.sticker(23);
      expect(targetSticker.type, equals(TargetType.sticker));
      expect(targetSticker.index, equals(23));

      const targetEdge = CalibrationTarget.edge(EdgeGroup.left);
      expect(targetEdge.type, equals(TargetType.edge));
      expect(targetEdge.edgeGroup, equals(EdgeGroup.left));
    });

    test('enforces non-negative index constraints', () {
      expect(() => CalibrationTarget.row(-1), throwsA(isA<AssertionError>()));
      expect(() => CalibrationTarget.column(-1), throwsA(isA<AssertionError>()));
      expect(() => CalibrationTarget.sticker(-5), throwsA(isA<AssertionError>()));
    });

    test('raw constructor enforces structural constraints', () {
      // Sheet cannot have index or edge group
      expect(
        () => CalibrationTarget.raw(
          type: TargetType.sheet,
          index: 0,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Row, Column, Sticker must have non-negative index
      expect(
        () => CalibrationTarget.raw(
          type: TargetType.row,
          index: null,
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => CalibrationTarget.raw(
          type: TargetType.column,
          index: -1,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Edge must have non-null edge group
      expect(
        () => CalibrationTarget.raw(
          type: TargetType.edge,
          edgeGroup: null,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('supports Equatable value equality', () {
      const target1 = CalibrationTarget.row(3);
      const target2 = CalibrationTarget.row(3);
      const target3 = CalibrationTarget.row(2);
      const targetEdge1 = CalibrationTarget.edge(EdgeGroup.left);
      const targetEdge2 = CalibrationTarget.edge(EdgeGroup.left);

      expect(target1, equals(target2));
      expect(target1, isNot(equals(target3)));
      expect(targetEdge1, equals(targetEdge2));
      expect(targetEdge1, isNot(equals(target1)));
    });
  });

  group('PrinterCalibration Rules Constraints Tests', () {
    const testTarget = CalibrationTarget.sheet();
    const testTransform = PrintStickerTransform.identity();
    const testRule = CalibrationRule(
      target: testTarget,
      transformation: testTransform,
    );

    test('disabled calibration can have empty rules', () {
      final calibration = PrinterCalibration(
        enabled: false,
        calibrationRules: const [],
      );
      expect(calibration.enabled, isFalse);
      expect(calibration.calibrationRules, isEmpty);
    });

    test('enabled calibration requires at least one rule', () {
      expect(
        () => PrinterCalibration(
          enabled: true,
          calibrationRules: const [],
        ),
        throwsA(isA<AssertionError>()),
      );

      final calibration = PrinterCalibration(
        enabled: true,
        calibrationRules: const [testRule],
      );
      expect(calibration.enabled, isTrue);
      expect(calibration.calibrationRules, isNotEmpty);
    });
  });

  group('Transformation Compatibility Verification', () {
    test('CalibrationRule supports offsets, scaling, and anchored scaling', () {
      const target = CalibrationTarget.sticker(5);
      
      // 1. Translation offsets
      const offsetTransform = PrintStickerTransform(offsetX: 1.5, offsetY: -2);
      const rule1 = CalibrationRule(
        target: target,
        transformation: offsetTransform,
      );
      expect(rule1.transformation.offsetX, equals(1.5));
      expect(rule1.transformation.offsetY, equals(-2));
      expect(rule1.transformation.scaleX, equals(1.0));
      expect(rule1.transformation.scaleY, equals(1.0));
      expect(rule1.transformation.anchorX, equals(0.5));
      expect(rule1.transformation.anchorY, equals(0.5));

      // 2. Scaling & Anchors
      const scaledTransform = PrintStickerTransform(
        scaleX: 0.95,
        scaleY: 0.98,
        anchorX: 0,
        anchorY: 1,
      );
      const rule2 = CalibrationRule(
        target: target,
        transformation: scaledTransform,
      );
      expect(rule2.transformation.scaleX, equals(0.95));
      expect(rule2.transformation.scaleY, equals(0.98));
      expect(rule2.transformation.anchorX, equals(0.0));
      expect(rule2.transformation.anchorY, equals(1.0));
    });
  });

  group('PrinterProfile & Tray Profile Constraints', () {
    const testIdentity = PrinterIdentity(systemPrinterName: 'Zebra');
    const testCapabilities = PrinterCapabilities(
      supportsCustomPaperSize: true,
      supportsPortraitCustomPaper: true,
      supportsLandscapeCustomPaper: false,
      supportsManualFeed: false,
      supportsBorderlessPrinting: false,
      supportsTraySelection: true,
    );
    const testPreferences = OptimizationPreferences(
      allowScaling: true,
      allowTranslation: true,
      allowStickerSpecificAdjustment: true,
    );
    final testTray = PrinterTrayProfile(
      trayIdentifier: 'tray_1',
      displayName: 'Tray 1',
      supportedPaperConfigurations: const [],
      calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
    );

    test('PrinterTrayProfile enforces identifier and name limits', () {
      expect(
        () => PrinterTrayProfile(
          trayIdentifier: '',
          displayName: 'Tray 1',
          supportedPaperConfigurations: const [],
          calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PrinterTrayProfile(
          trayIdentifier: 'tray_1',
          displayName: '',
          supportedPaperConfigurations: const [],
          calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('PrinterProfile validation enforces id, displayName, and configured trays presence', () {
      final now = DateTime.now();

      // Empty id
      expect(
        () => PrinterProfile(
          id: '',
          displayName: 'Office Profile',
          status: PrinterProfileStatus.active,
          printerIdentity: testIdentity,
          capabilities: testCapabilities,
          optimizationPreferences: testPreferences,
          trays: [testTray],
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Empty displayName
      expect(
        () => PrinterProfile(
          id: 'prof-123',
          displayName: '',
          status: PrinterProfileStatus.active,
          printerIdentity: testIdentity,
          capabilities: testCapabilities,
          optimizationPreferences: testPreferences,
          trays: [testTray],
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );

      // Empty trays list
      expect(
        () => PrinterProfile(
          id: 'prof-123',
          displayName: 'Office Profile',
          status: PrinterProfileStatus.active,
          printerIdentity: testIdentity,
          capabilities: testCapabilities,
          optimizationPreferences: testPreferences,
          trays: const [],
          createdAt: now,
          updatedAt: now,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('enforces immutability: list fields are wrapped with List.unmodifiable and cannot be mutated externally', () {
      final now = DateTime.now();

      // 1. PrinterProfile trays list mutation test
      final trayList = [testTray];
      final profile = PrinterProfile(
        id: 'prof-1',
        displayName: 'Test Profile',
        status: PrinterProfileStatus.active,
        printerIdentity: testIdentity,
        capabilities: testCapabilities,
        optimizationPreferences: testPreferences,
        trays: trayList,
        createdAt: now,
        updatedAt: now,
      );

      // Attempt to modify the original list passed to constructor
      trayList.add(
        PrinterTrayProfile(
          trayIdentifier: 'tray_2',
          displayName: 'Tray 2',
          supportedPaperConfigurations: const [],
          calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
        ),
      );
      // Entity list must remain unchanged (length 1)
      expect(profile.trays.length, equals(1));

      // Attempt direct mutation of the unmodifiable list inside the entity (should throw UnsupportedError)
      expect(() => profile.trays.add(testTray), throwsA(isA<UnsupportedError>()));

      // 2. PrinterTrayProfile supportedPaperConfigurations list mutation test
      const paperRef = PaperConfigurationReference(id: 'ref-1', displayName: 'Ref 1');
      final refList = [paperRef];
      final tray = PrinterTrayProfile(
        trayIdentifier: 'tray_1',
        displayName: 'Tray 1',
        supportedPaperConfigurations: refList,
        calibration: PrinterCalibration(enabled: false, calibrationRules: const []),
      );

      refList.add(const PaperConfigurationReference(id: 'ref-2', displayName: 'Ref 2'));
      expect(tray.supportedPaperConfigurations.length, equals(1));
      expect(() => tray.supportedPaperConfigurations.add(paperRef), throwsA(isA<UnsupportedError>()));

      // 3. PrinterCalibration calibrationRules list mutation test
      const testTarget = CalibrationTarget.sheet();
      const testTransform = PrintStickerTransform.identity();
      const testRule = CalibrationRule(target: testTarget, transformation: testTransform);
      final rulesList = [testRule];
      final calibration = PrinterCalibration(
        enabled: true,
        calibrationRules: rulesList,
      );

      rulesList.add(const CalibrationRule(target: testTarget, transformation: testTransform));
      expect(calibration.calibrationRules.length, equals(1));
      expect(() => calibration.calibrationRules.add(testRule), throwsA(isA<UnsupportedError>()));
    });
  });
}
