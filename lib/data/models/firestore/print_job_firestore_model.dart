import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/domain.dart';

/// Firestore persistence model for Print Jobs.
class PrintJobFirestoreModel {
  PrintJobFirestoreModel({
    required this.id,
    required this.productName,
    required this.sku,
    required this.status,
    required this.printerStation,
    required this.printedAt,
    required this.labelCount,
    required this.isVerified,
  });

  factory PrintJobFirestoreModel.fromDomain(PrintJob j) {
    return PrintJobFirestoreModel(
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

  factory PrintJobFirestoreModel.fromMap(String id, Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return PrintJobFirestoreModel(
      id: id,
      productName: json['productName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      status: json['status'] as String? ?? 'completed',
      printerStation: json['printerStation'] as String? ?? '',
      printedAt: parseDateTime(json['printedAt']),
      labelCount: json['labelCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }

  final String id;
  final String productName;
  final String sku;
  final String status;
  final String printerStation;
  final DateTime printedAt;
  final int labelCount;
  final bool isVerified;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productName': productName,
      'sku': sku,
      'status': status,
      'printerStation': printerStation,
      'printedAt': Timestamp.fromDate(printedAt),
      'labelCount': labelCount,
      'isVerified': isVerified,
    };
  }

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
