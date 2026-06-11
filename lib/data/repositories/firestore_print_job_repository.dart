import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

/// Firestore-based implementation of [PrintJobRepository] partitioned by user.
class FirestorePrintJobRepository implements PrintJobRepository {
  /// Creates a [FirestorePrintJobRepository] instance.
  FirestorePrintJobRepository({
    required FirebaseFirestore firestore,
    required String userId,
  })  : _firestore = firestore,
        _userId = userId;

  final FirebaseFirestore _firestore;
  final String _userId;

  CollectionReference<Map<String, dynamic>> get _jobsRef =>
      _firestore.collection('users').doc(_userId).collection('print_jobs');

  @override
  Future<void> savePrintJob(PrintJob job) async {
    await _jobsRef.doc(job.id).set(_jobToJson(job));
  }

  @override
  Future<List<PrintJob>> getRecentJobs({int limit = 10}) async {
    final snapshot = await _jobsRef
        .orderBy('printedAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs.map((doc) => _jobFromFirestore(doc.id, doc.data())).toList();
  }

  @override
  Future<List<PrintJob>> getJobsBySku(String sku) async {
    final snapshot = await _jobsRef.where('sku', isEqualTo: sku).get();
    final list = snapshot.docs.map((doc) => _jobFromFirestore(doc.id, doc.data())).toList()
      ..sort((a, b) => b.printedAt.compareTo(a.printedAt));
    return list;
  }

  Map<String, dynamic> _jobToJson(PrintJob j) {
    return {
      'id': j.id,
      'productName': j.productName,
      'sku': j.sku,
      'status': j.status.name,
      'printerStation': j.printerStation,
      'printedAt': Timestamp.fromDate(j.printedAt),
      'labelCount': j.labelCount,
      'isVerified': j.isVerified,
    };
  }

  PrintJob _jobFromFirestore(String id, Map<String, dynamic> json) {
    DateTime parseDateTime(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.parse(value);
      }
      return DateTime.now();
    }

    return PrintJob(
      id: id,
      productName: json['productName'] as String? ?? '',
      sku: json['sku'] as String? ?? '',
      status: PrintJobStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PrintJobStatus.completed,
      ),
      printerStation: json['printerStation'] as String? ?? '',
      printedAt: parseDateTime(json['printedAt']),
      labelCount: json['labelCount'] as int? ?? 0,
      isVerified: json['isVerified'] as bool? ?? false,
    );
  }
}
