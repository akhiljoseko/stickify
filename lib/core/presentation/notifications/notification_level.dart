/// Severity level of a notification event.
enum NotificationLevel {
  /// Operation completed as expected.
  success,

  /// General informational message.
  info,

  /// Non-critical warning.
  warning,

  /// Non-blocking error notification.
  error,
}
