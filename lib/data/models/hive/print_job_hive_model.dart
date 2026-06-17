import 'package:hive_ce/hive.dart';
import 'package:stickify/domain/domain.dart';

class PrintJobHiveModel extends HiveObject {
  PrintJobHiveModel({
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

  factory PrintJobHiveModel.fromDomain(PrintJob j) {
    return PrintJobHiveModel(
      id: j.id,
      productId: j.productId,
      productName: j.productName,
      variantId: j.variantId,
      variantName: j.variantName,
      variantSku: j.variantSku,
      templateId: j.templateId,
      templateName: j.templateName,
      printerStation: j.printerStation,
      printedAt: j.printedAt,
      labelCount: j.labelCount,
    );
  }

  final String id;
  final String productId;
  final String productName;
  final String variantId;
  final String variantName;
  final String variantSku;
  final String templateId;
  final String templateName;
  final String printerStation;
  final DateTime printedAt;
  final int labelCount;

  PrintJob toDomain() {
    return PrintJob(
      id: id,
      productId: productId,
      productName: productName,
      variantId: variantId,
      variantName: variantName,
      variantSku: variantSku,
      templateId: templateId,
      templateName: templateName,
      printerStation: printerStation,
      printedAt: printedAt,
      labelCount: labelCount,
    );
  }
}
