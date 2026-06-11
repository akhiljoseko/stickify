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
  const MockPrintJobRepository();

  /// Realistic mock data sourced directly from the Stitch dashboard design.
  static final List<PrintJob> _mockJobs = [
    PrintJob(
      id: 'job-001',
      productName: 'Pro-X Gaming Headset',
      sku: 'GAM-2024-XP01',
      status: PrintJobStatus.completed,
      printerStation: 'Station #03',
      printedAt: DateTime(2023, 10, 24, 14, 30),
      labelCount: 48,
      isVerified: true,
    ),
    PrintJob(
      id: 'job-002',
      productName: 'Industrial Drill Bit Set',
      sku: 'TL-DR-9922',
      status: PrintJobStatus.completed,
      printerStation: 'Station #01',
      printedAt: DateTime(2023, 10, 24, 12, 10),
      labelCount: 120,
    ),
    PrintJob(
      id: 'job-003',
      productName: 'LED Panel XL-400',
      sku: 'LT-LP-0400',
      status: PrintJobStatus.completed,
      printerStation: 'Station #02',
      printedAt: DateTime(2023, 10, 23, 9, 45),
      labelCount: 24,
      isVerified: true,
    ),
    PrintJob(
      id: 'job-004',
      productName: 'Organic Cold Brew 12oz',
      sku: 'BEV-CB-ORG-12',
      status: PrintJobStatus.printing,
      printerStation: 'Station #02',
      printedAt: DateTime(2023, 10, 25, 8),
      labelCount: 200,
    ),PrintJob(
      id: 'job-005',
      productName: 'Eco-Wrap Large 50m',
      sku: 'PKG-EW-LRG-50',
      status: PrintJobStatus.queued,
      printerStation: 'Station #05',
      printedAt: DateTime(2023, 10, 25, 8, 15),
      labelCount: 60,
    ),
  ];

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    // Simulate a 600ms network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final jobs = _mockJobs;
    return jobs.take(limit).toList();
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    await Future<void>.delayed(const Duration(milliseconds: 400));
    return _mockJobs.where((j) => j.sku == sku).toList();
  }

  @override
  Future<void> savePrintJob(PrintJob job) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    _mockJobs.insert(0, job);
  }
}
