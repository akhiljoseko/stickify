import 'package:flutter/foundation.dart';
import 'package:stickify/core/presentation/notifications/notification_level.dart';

/// Data payload for a single notification display event.
@immutable
class NotificationEvent {
  /// Creates a [NotificationEvent].
  const NotificationEvent({
    required this.level,
    required this.message,
    this.title,
    this.id = 0,
  });

  /// Severity level.
  final NotificationLevel level;

  /// The body text to display.
  final String message;

  /// Optional heading text.
  final String? title;

  /// Monotonically increasing ID used to differentiate consecutive events.
  final int id;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationEvent &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
