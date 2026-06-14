import 'package:equatable/equatable.dart';

enum SyncAction {
  save,
  delete,
}

class SyncOperation extends Equatable {
  const SyncOperation({
    required this.id,
    required this.collection,
    required this.action,
    required this.timestamp,
  });

  factory SyncOperation.fromMap(Map<dynamic, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      collection: map['collection'] as String,
      action: SyncAction.values.byName(map['action'] as String),
      timestamp: map['timestamp'] as int,
    );
  }

  final String id;
  final String collection;
  final SyncAction action;
  final int timestamp;

  @override
  List<Object?> get props => [id, collection, action, timestamp];

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'collection': collection,
      'action': action.name,
      'timestamp': timestamp,
    };
  }
}
