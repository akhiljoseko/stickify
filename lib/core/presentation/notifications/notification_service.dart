import 'dart:async';
import 'package:stickify/core/presentation/notifications/notification_event.dart';
import 'package:stickify/core/presentation/notifications/notification_level.dart';

/// Singleton service that broadcasts notification events to one or more
/// platform-adaptive UI listeners.
///
/// Each new event cancels any pending auto-dismiss timer for the previous
/// event so that only one notification is visible at a time.
class NotificationService {
  NotificationService() : _eventController = StreamController<NotificationEvent>.broadcast();

  final StreamController<NotificationEvent> _eventController;
  int _nextId = 0;
  Timer? _dismissTimer;

  /// Broadcast stream of notification events.
  Stream<NotificationEvent> get events => _eventController.stream;

  /// Show a success notification.
  void showSuccess(String message, {String? title}) {
    _emit(NotificationLevel.success, message, title: title);
  }

  /// Show an informational notification.
  void showInfo(String message, {String? title}) {
    _emit(NotificationLevel.info, message, title: title);
  }

  /// Show a warning notification.
  void showWarning(String message, {String? title}) {
    _emit(NotificationLevel.warning, message, title: title);
  }

  /// Show a non-fatal error notification.
  void showError(String message, {String? title}) {
    _emit(NotificationLevel.error, message, title: title);
  }

  void _emit(NotificationLevel level, String message, {String? title}) {
    _dismissTimer?.cancel();
    _nextId++;
    final event = NotificationEvent(
      level: level,
      message: message,
      title: title,
      id: _nextId,
    );
    _eventController.add(event);
  }

  /// Dismiss the current notification early.
  void dismiss() {
    _dismissTimer?.cancel();
    _nextId++;
    _eventController.add(
      NotificationEvent(level: NotificationLevel.info, message: '', id: _nextId),
    );
  }

  /// Dispose internal resources.
  void dispose() {
    _dismissTimer?.cancel();
    _eventController.close();
  }
}
