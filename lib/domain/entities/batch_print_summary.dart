import 'package:equatable/equatable.dart';

/// Represents a combined summary item of a single variant printed in a batch.
class BatchPrintSummaryItem extends Equatable {
  /// Creates a [BatchPrintSummaryItem].
  const BatchPrintSummaryItem({
    required this.productId,
    required this.productName,
    required this.variantSku,
    required this.variantName,
    required this.quantity,
    this.imageUrl,
  });

  /// Unique identifier of the product.
  final String productId;

  /// Display name of the product.
  final String productName;

  /// SKU identifier of the variant.
  final String variantSku;

  /// Display name of the variant.
  final String variantName;

  /// Combined total quantity printed for this variant in the batch.
  final int quantity;

  /// Optional thumbnail image URL for the product.
  final String? imageUrl;

  /// Constructs a [BatchPrintSummaryItem] from a JSON map.
  factory BatchPrintSummaryItem.fromJson(Map<String, dynamic> json) {
    return BatchPrintSummaryItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      variantSku: json['variantSku'] as String,
      variantName: json['variantName'] as String,
      quantity: (json['quantity'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Creates a copy of this [BatchPrintSummaryItem] with updated properties.
  BatchPrintSummaryItem copyWith({
    String? productId,
    String? productName,
    String? variantSku,
    String? variantName,
    int? quantity,
    String? imageUrl,
  }) {
    return BatchPrintSummaryItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      variantSku: variantSku ?? this.variantSku,
      variantName: variantName ?? this.variantName,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  /// Converts this item to a JSON map for persistence.
  Map<String, dynamic> toJson() => {
        'productId': productId,
        'productName': productName,
        'variantSku': variantSku,
        'variantName': variantName,
        'quantity': quantity,
        'imageUrl': imageUrl,
      };

  @override
  List<Object?> get props => [
        productId,
        productName,
        variantSku,
        variantName,
        quantity,
        imageUrl,
      ];
}

/// Represents the overall summary record of a completed batch print job.
class BatchPrintSummary extends Equatable {
  /// Creates a [BatchPrintSummary].
  const BatchPrintSummary({
    required this.id,
    required this.printedAt,
    required this.templateId,
    required this.templateName,
    required this.printerName,
    required this.totalQuantity,
    required this.totalSheets,
    required this.items,
  });

  /// Unique identifier for this batch summary record.
  final String id;

  /// Date and time when the batch print job was completed.
  final DateTime printedAt;

  /// Identifier of the label template used.
  final String templateId;

  /// Display name of the label template used.
  final String templateName;

  /// Station / system printer name used.
  final String printerName;

  /// Total number of individual labels printed in this batch.
  final int totalQuantity;

  /// Total physical sheets required/printed.
  final int totalSheets;

  /// List of combined variant summary items printed in this batch.
  final List<BatchPrintSummaryItem> items;

  /// Constructs a [BatchPrintSummary] from a JSON map.
  factory BatchPrintSummary.fromJson(Map<String, dynamic> json) {
    return BatchPrintSummary(
      id: json['id'] as String,
      printedAt: DateTime.parse(json['printedAt'] as String),
      templateId: json['templateId'] as String,
      templateName: json['templateName'] as String,
      printerName: json['printerName'] as String,
      totalQuantity: (json['totalQuantity'] as num).toInt(),
      totalSheets: (json['totalSheets'] as num).toInt(),
      items: (json['items'] as List<dynamic>)
          .map((i) => BatchPrintSummaryItem.fromJson(Map<String, dynamic>.from(i as Map)))
          .toList(),
    );
  }

  /// Human-readable primary batch title formatted from date & time of print.
  String get batchTitle {
    final day = printedAt.day.toString().padLeft(2, '0');
    final month = _monthAbbr(printedAt.month);
    final year = printedAt.year;
    final hourNum = printedAt.hour == 0 ? 12 : (printedAt.hour > 12 ? printedAt.hour - 12 : printedAt.hour);
    final hour = hourNum.toString().padLeft(2, '0');
    final minute = printedAt.minute.toString().padLeft(2, '0');
    final period = printedAt.hour >= 12 ? 'PM' : 'AM';

    return '$day $month $year, $hour:$minute $period';
  }

  static String _monthAbbr(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    if (month >= 1 && month <= 12) return months[month - 1];
    return '';
  }

  /// Converts this entity to a JSON map for local database storage.
  Map<String, dynamic> toJson() => {
        'id': id,
        'printedAt': printedAt.toIso8601String(),
        'templateId': templateId,
        'templateName': templateName,
        'printerName': printerName,
        'totalQuantity': totalQuantity,
        'totalSheets': totalSheets,
        'items': items.map((i) => i.toJson()).toList(),
      };

  @override
  List<Object?> get props => [
        id,
        printedAt,
        templateId,
        templateName,
        printerName,
        totalQuantity,
        totalSheets,
        items,
      ];
}
