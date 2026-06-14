import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

part 'print_job_hive_model.g.dart';

@HiveType(typeId: 9)
class PrintJobHiveModel extends HiveObject {
  PrintJobHiveModel({
    required this.id,
    required this.productName,
    required this.variantId,
    required this.variantName,
    required this.variantSku,
    required this.templateId,
    required this.templateName,
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
      variantId: j.variantId,
      variantName: j.variantName,
      variantSku: j.variantSku,
      templateId: j.templateId,
      templateName: j.templateName,
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
  final String variantId;

  @HiveField(3)
  final String variantName;

  @HiveField(4)
  final String variantSku;

  @HiveField(5)
  final String templateId;

  @HiveField(6)
  final String templateName;

  @HiveField(7)
  final String status;

  @HiveField(8)
  final String printerStation;

  @HiveField(9)
  final DateTime printedAt;

  @HiveField(10)
  final int labelCount;

  @HiveField(11)
  final bool isVerified;

  PrintJob toDomain() {
    return PrintJob(
      id: id,
      productName: productName,
      variantId: variantId,
      variantName: variantName,
      variantSku: variantSku,
      templateId: templateId,
      templateName: templateName,
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
