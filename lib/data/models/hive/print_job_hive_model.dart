import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

part 'print_job_hive_model.g.dart';

@HiveType(typeId: 9)
class PrintJobHiveModel extends HiveObject {
  PrintJobHiveModel({
    required this.id,
    required this.productName,
    required this.sku,
    required this.status,
    required this.printerStation,
    required this.printedAt,
    required this.labelCount,
    required this.isVerified,
  });

  factory PrintJobHiveModel.fromDomain(PrintJob j) {
    return PrintJobHiveModel(
      id: j.id,
      productName: j.productName,
      sku: j.sku,
      status: j.status.name,
      printerStation: j.printerStation,
      printedAt: j.printedAt,
      labelCount: j.labelCount,
      isVerified: j.isVerified,
    );
  }

  @HiveField(0)
  final String id;

  @HiveField(1)
  final String productName;

  @HiveField(2)
  final String sku;

  @HiveField(3)
  final String status;

  @HiveField(4)
  final String printerStation;

  @HiveField(5)
  final DateTime printedAt;

  @HiveField(6)
  final int labelCount;

  @HiveField(7)
  final bool isVerified;

  PrintJob toDomain() {
    return PrintJob(
      id: id,
      productName: productName,
      sku: sku,
      status: PrintJobStatus.values.firstWhere(
        (e) => e.name == status,
        orElse: () => PrintJobStatus.completed,
      ),
      printerStation: printerStation,
      printedAt: printedAt,
      labelCount: labelCount,
      isVerified: isVerified,
    );
  }
}
