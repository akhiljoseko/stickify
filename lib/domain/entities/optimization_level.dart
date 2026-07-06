/// Represents the hierarchy of print optimization levels applied to resolve
/// printable region conflicts on a printer.
enum OptimizationLevel {
  /// No adjustments are necessary.
  noModification,

  /// A single global translation is applied to all stickers.
  globalTransform,

  /// Independent translations are applied to specific edge groups.
  edgeGroupTranslation,

  /// Scaling adjustments are applied to specific edge groups.
  edgeGroupScaling,

  /// Individual sticker adjustments are applied (not implemented).
  individualSticker,

  /// The conflicts cannot be resolved under the current constraints.
  unsupported,
}
