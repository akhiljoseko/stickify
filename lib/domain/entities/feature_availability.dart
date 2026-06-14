/// Status modes describing a feature's availability within the current environment.
enum FeatureAvailability {
  /// Feature is fully operational.
  available,

  /// Feature operates with specific mobile/tablet UI simplifications.
  limited,

  /// Feature requires full-screen desktop pointer/keyboard workspace.
  desktopOnly,

  /// Feature requires touch-first mobile environment sensors.
  mobileOnly,

  /// Feature is completely disabled or unsupported in this build/environment.
  unavailable,
}
