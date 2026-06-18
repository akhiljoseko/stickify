import 'dart:async';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

/// Mock implementation of [PrintJobRepository].
///
/// Returns realistic hardcoded print job data matching the Stitch dashboard
/// design. Replace this with a real network/database implementation when
/// the backend is ready. The Cubits depend only on [PrintJobRepository],
/// so swapping implementations requires zero UI changes.
class MockPrintJobRepository implements PrintJobRepository {
  /// Creates a [MockPrintJobRepository] instance.
  MockPrintJobRepository();
  final StreamController<PrintJob> _createdController = StreamController<PrintJob>.broadcast();

  @override
  Stream<PrintJob> get onPrintJobCreated => _createdController.stream;

  /// Realistic mock data sourced directly from the Stitch dashboard design.
  static final List<PrintJob> _mockJobs = [
    PrintJob(
      id: 'job-001',
      productId: 'prod-001',
      productName: 'Pro-X Gaming Headset',
      variantId: 'GAM-2024-XP01',
      variantName: 'Standard',
      variantSku: 'GAM-2024-XP01',
      templateId: 'template-001',
      templateName: 'Standard Shipping',
      printerStation: 'Station #03',
      printedAt: DateTime(2023, 10, 24, 14, 30),
      labelCount: 48,
      imageUrl: null,
    ),
    PrintJob(
      id: 'job-002',
      productId: 'prod-002',
      productName: 'Industrial Drill Bit Set',
      variantId: 'TL-DR-9922',
      variantName: 'Standard',
      variantSku: 'TL-DR-9922',
      templateId: 'template-002',
      templateName: 'Standard Shipping',
      printerStation: 'Station #01',
      printedAt: DateTime(2023, 10, 24, 12, 10),
      labelCount: 120,
      imageUrl: null,
    ),
    PrintJob(
      id: 'job-003',
      productId: 'prod-003',
      productName: 'LED Panel XL-400',
      variantId: 'LT-LP-0400',
      variantName: 'Standard',
      variantSku: 'LT-LP-0400',
      templateId: 'template-001',
      templateName: 'Standard Shipping',
      printerStation: 'Station #02',
      printedAt: DateTime(2023, 10, 23, 9, 45),
      labelCount: 24,
      imageUrl: null,
    ),
    PrintJob(
      id: 'job-004',
      productId: 'prod-004',
      productName: 'Organic Cold Brew 12oz',
      variantId: 'BEV-CB-ORG-12',
      variantName: 'Standard',
      variantSku: 'BEV-CB-ORG-12',
      templateId: 'template-003',
      templateName: 'Standard Shipping',
      printerStation: 'Station #02',
      printedAt: DateTime(2023, 10, 25, 8),
      labelCount: 200,
      imageUrl: null,
    ),
    PrintJob(
      id: 'job-005',
      productId: 'prod-005',
      productName: 'Eco-Wrap Large 50m',
      variantId: 'PKG-EW-LRG-50',
      variantName: 'Standard',
      variantSku: 'PKG-EW-LRG-50',
      templateId: 'template-001',
      templateName: 'Standard Shipping',
      printerStation: 'Station #05',
      printedAt: DateTime(2023, 10, 25, 8, 15),
      labelCount: 60,
      imageUrl: null,
    ),
  ];

  @override
  Future<Result<List<PrintJob>, AppError>> getRecentJobs({int limit = 10}) async {
    // Simulate a 600ms network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final jobs = _mockJobs;
    return Result.success(jobs.take(limit).toList());
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsPaginated({int limit = 20, DateTime? before}) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    var jobs = _mockJobs;
    if (before != null) {
      jobs = jobs.where((j) => j.printedAt.isBefore(before)).toList();
    }
    return Result.success(jobs.take(limit).toList());
  }

  @override
  Future<Result<List<PrintJob>, AppError>> getJobsByVariantSku(String variantSku) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    final filtered = _mockJobs.where((j) => j.variantSku == variantSku).toList();
    return Result.success(filtered);
  }

  @override
  Future<Result<void, AppError>> savePrintJob(PrintJob job) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockJobs.insert(0, job);
    _createdController.add(job);
    return const Result.success(null);
  }
}
