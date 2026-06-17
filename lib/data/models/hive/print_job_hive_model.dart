import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

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

  final String id;
  final String productName;
  final String variantId;
  final String variantName;
  final String variantSku;
  final String templateId;
  final String templateName;
  final String status;
  final String printerStation;
  final DateTime printedAt;
  final int labelCount;
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
