import 'package:equatable/equatable.dart';

/// Represents the lifecycle status of a single print job.
enum PrintJobStatus {
  /// The job completed successfully and has been verified.
  completed,

  /// The job is actively being processed by a printer.
  printing,

  /// The job is queued and waiting for a printer to become available.
  queued,

  /// The job failed due to a hardware or connectivity error.
  error,
}

/// A pure business entity representing a single label print job.
///
/// This entity belongs to the global domain layer and must contain no
/// Flutter or framework imports. It is fed into the UI via Cubits.
///
/// ## Fields
/// - [id] — Unique job identifier (UUID or server-assigned key).
/// - [productName] — Human-readable product name shown on the dashboard.
/// - [sku] — Stock-keeping unit code rendered in monospaced label font.
/// - [status] — Current lifecycle status of this print job.
/// - [printerStation] — The hardware station that processed/is processing
///   this job (e.g., `'Station #02'`).
/// - [printedAt] — The timestamp when printing started or was last updated.
/// - [labelCount] — Total number of individual labels in this batch.
/// - [isVerified] — Whether the printed output has been quality-verified.
class PrintJob extends Equatable {
  const PrintJob({
    required this.id,
    required this.productName,
    required this.sku,
    required this.status,
    required this.printerStation,
    required this.printedAt,
    required this.labelCount,
    this.isVerified = false,
  });

  /// Unique identifier for this print job.
  final String id;

  /// Human-readable product name (e.g., `'Pro-X Gaming Headset'`).
  final String productName;

  /// SKU code (e.g., `'GAM-2024-XP01'`). Rendered in JetBrains Mono.
  final String sku;

  /// Current lifecycle status of this print job.
  final PrintJobStatus status;

  /// The printer station assigned to this job (e.g., `'Station #02'`).
  final String printerStation;

  /// Timestamp when printing started or was last updated.
  final DateTime printedAt;

  /// Total number of labels in this batch.
  final int labelCount;

  /// Whether the printed output has been verified for quality.
  final bool isVerified;

  @override
  List<Object?> get props => [
        id,
        productName,
        sku,
        status,
        printerStation,
        printedAt,
        labelCount,
        isVerified,
      ];

  /// Creates a copy of this [PrintJob] with the given fields replaced.
  PrintJob copyWith({
    String? id,
    String? productName,
    String? sku,
    PrintJobStatus? status,
    String? printerStation,
    DateTime? printedAt,
    int? labelCount,
    bool? isVerified,
  }) {
    return PrintJob(
      id: id ?? this.id,
      productName: productName ?? this.productName,
      sku: sku ?? this.sku,
      status: status ?? this.status,
      printerStation: printerStation ?? this.printerStation,
      printedAt: printedAt ?? this.printedAt,
      labelCount: labelCount ?? this.labelCount,
      isVerified: isVerified ?? this.isVerified,
    );
  }
}
