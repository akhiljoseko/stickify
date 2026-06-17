import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stickify/core/presentation/notifications/notification_event.dart';
import 'package:stickify/core/presentation/notifications/notification_level.dart';
import 'package:stickify/core/presentation/notifications/notification_service.dart';

void main() {
  group('NotificationService', () {
    late NotificationService service;
    late List<NotificationEvent> events;
    late StreamSubscription<NotificationEvent> sub;

    setUp(() {
      service = NotificationService();
      events = [];
      sub = service.events.listen((e) => events.add(e));
    });

    tearDown(() {
      sub.cancel();
      service.dispose();
    });

    test('showSuccess emits success event with message', () async {
      service.showSuccess('Operation completed!');

      await Future<void>.microtask(() {});
      expect(events, hasLength(1));
      expect(events.last.level, NotificationLevel.success);
      expect(events.last.message, 'Operation completed!');
    });

    test('showInfo emits info event with message', () async {
      service.showInfo('Heads up');

      await Future<void>.microtask(() {});
      expect(events.last.level, NotificationLevel.info);
      expect(events.last.message, 'Heads up');
    });

    test('showWarning emits warning event with message', () async {
      service.showWarning('Watch out');

      await Future<void>.microtask(() {});
      expect(events.last.level, NotificationLevel.warning);
      expect(events.last.message, 'Watch out');
    });

    test('showError emits error event with message', () async {
      service.showError('Something failed');

      await Future<void>.microtask(() {});
      expect(events.last.level, NotificationLevel.error);
      expect(events.last.message, 'Something failed');
    });

    test('showSuccess with title emits event with title', () async {
      service.showSuccess('File saved', title: 'Success');

      await Future<void>.microtask(() {});
      expect(events.last.title, 'Success');
    });

    test('multiple events are emitted in order', () async {
      service.showSuccess('First');
      await Future<void>.microtask(() {});
      service.showInfo('Second');
      await Future<void>.microtask(() {});
      service.showError('Third');
      await Future<void>.microtask(() {});

      expect(events, hasLength(3));
      expect(events[0].level, NotificationLevel.success);
      expect(events[0].message, 'First');
      expect(events[1].level, NotificationLevel.info);
      expect(events[1].message, 'Second');
      expect(events[2].level, NotificationLevel.error);
      expect(events[2].message, 'Third');
    });

    test('does not emit after dispose', () async {
      service.dispose();
      expect(() => service.showSuccess('Should not fire'), throwsA(isA<StateError>()));
    });
  });
}
