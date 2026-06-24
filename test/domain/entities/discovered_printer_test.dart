import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/domain/domain.dart';

void main() {
  group('DiscoveredPrinter Validation & Equality Tests', () {
    test('enforces systemPrinterName is not empty', () {
      expect(
        () => DiscoveredPrinter(
          systemPrinterName: '',
          status: DiscoveredPrinterStatus.online,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('sets default metadata to empty strings if not specified', () {
      const printer = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
      );

      expect(printer.systemPrinterName, equals('Zebra ZT411'));
      expect(printer.status, equals(DiscoveredPrinterStatus.online));
      expect(printer.manufacturer, isEmpty);
      expect(printer.model, isEmpty);
      expect(printer.driverName, isEmpty);
      expect(printer.driverVersion, isEmpty);
    });

    test('retains provided metadata values', () {
      const printer = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra Technologies',
        model: 'ZT411-300dpi',
        driverName: 'Zebra ZDesigner ZT411',
        driverVersion: '8.4.1.20258',
      );

      expect(printer.systemPrinterName, equals('Zebra ZT411'));
      expect(printer.status, equals(DiscoveredPrinterStatus.online));
      expect(printer.manufacturer, equals('Zebra Technologies'));
      expect(printer.model, equals('ZT411-300dpi'));
      expect(printer.driverName, equals('Zebra ZDesigner ZT411'));
      expect(printer.driverVersion, equals('8.4.1.20258'));
    });

    test('supports Equatable value equality', () {
      const printer1 = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ZT411',
        driverName: 'ZDesigner',
        driverVersion: '1.0',
      );
      const printer2 = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
        manufacturer: 'Zebra',
        model: 'ZT411',
        driverName: 'ZDesigner',
        driverVersion: '1.0',
      );
      const printer3 = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.offline, // different status
        manufacturer: 'Zebra',
        model: 'ZT411',
        driverName: 'ZDesigner',
        driverVersion: '1.0',
      );

      expect(printer1, equals(printer2));
      expect(printer1, isNot(equals(printer3)));
    });

    test('has a helpful toString representation', () {
      const printer = DiscoveredPrinter(
        systemPrinterName: 'Zebra ZT411',
        status: DiscoveredPrinterStatus.online,
      );
      expect(
        printer.toString(),
        equals('DiscoveredPrinter(systemPrinterName: Zebra ZT411, status: DiscoveredPrinterStatus.online)'),
      );
    });
  });
}
