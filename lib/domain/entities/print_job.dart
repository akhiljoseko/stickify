import 'package:equatable/equatable.dart';

/// A pure business entity representing a single label print job.
///
/// This entity belongs to the global domain layer and must contain no
/// Flutter or framework imports. It is fed into the UI via Cubits.
class PrintJob extends Equatable {
  const PrintJob({
    required this.id,
    required this.productId,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.variantSku,
    required this.templateId,
    required this.templateName,
    required this.printerStation,
    required this.printedAt,
    required this.labelCount,
  });

  /// Unique identifier for this print job.
  final String id;

  /// Unique identifier of the parent product.
  final String productId;

  /// Human-readable product name (e.g., `'Pro-X Gaming Headset'`).
  final String productName;

  /// Unique identifier of the product variant.
  final String variantId;

  /// Human-readable name of the product variant (e.g., `'Black / 1TB'`).
  final String variantName;

  /// SKU code (e.g., `'GAM-2024-XP01'`).
  final String variantSku;

  /// Unique identifier of the template used.
  final String templateId;

  /// Human-readable name of the template used (e.g., `'Default Shipping Label'`).
  final String templateName;

  /// The printer station assigned to this job (e.g., `'Station #02'`).
  final String printerStation;

  /// Timestamp when printing started or was last updated.
  final DateTime printedAt;

  /// Total number of labels in this batch.
  final int labelCount;

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        variantId,
        variantName,
        variantSku,
        templateId,
        templateName,
        printerStation,
        printedAt,
        labelCount,
      ];

  /// Creates a copy of this [PrintJob] with the given fields replaced.
  PrintJob copyWith({
    String? id,
    String? productId,
    String? productName,
    String? variantId,
    String? variantName,
    String? variantSku,
    String? templateId,
    String? templateName,
    String? printerStation,
    DateTime? printedAt,
    int? labelCount,
  }) {
    return PrintJob(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantId: variantId ?? this.variantId,
      variantName: variantName ?? this.variantName,
      variantSku: variantSku ?? this.variantSku,
      templateId: templateId ?? this.templateId,
      templateName: templateName ?? this.templateName,
      printerStation: printerStation ?? this.printerStation,
      printedAt: printedAt ?? this.printedAt,
      labelCount: labelCount ?? this.labelCount,
    );
  }
}
