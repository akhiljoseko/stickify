import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stickify/core/services/remote_database_service.dart';

/// Concrete implementation of [RemoteDatabaseService] powered by Cloud Firestore.
class FirestoreRemoteDatabaseService implements RemoteDatabaseService {
  /// Creates a [FirestoreRemoteDatabaseService] backed by [firestore].
  FirestoreRemoteDatabaseService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  final FirebaseFirestore _firestore;

  @override
  Future<void> setData(String path, Map<String, dynamic> data) async {
    await _firestore.doc(path).set(data);
  }

  @override
  Future<void> deleteData(String path) async {
    await _firestore.doc(path).delete();
  }

  @override
  Future<Map<String, dynamic>?> getData(String path) async {
    final doc = await _firestore.doc(path).get();
    final data = doc.data();
    if (data == null) return null;
    return {
      ...data,
      'id': doc.id,
    };
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(
    String path, {
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    Query<Map<String, dynamic>> query = _firestore.collection(path);

    if (orderBy != null) {
      query = query.orderBy(orderBy, descending: descending);
    }
    if (limit != null) {
      query = query.limit(limit);
    }

    final snapshot = await query.get();
    return snapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(
    String path, {
    required String field,
    required dynamic isEqualTo,
  }) async {
    final snapshot = await _firestore
        .collection(path)
        .where(field, isEqualTo: isEqualTo)
        .get();

    return snapshot.docs.map((doc) {
      return {
        ...doc.data(),
        'id': doc.id,
      };
    }).toList();
  }
}
