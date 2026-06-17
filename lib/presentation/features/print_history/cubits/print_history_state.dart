import 'package:equatable/equatable.dart';
import 'package:stickify/domain/entities/print_job.dart';

sealed class PrintHistoryState extends Equatable {
  const PrintHistoryState();

  @override
  List<Object?> get props => [];
}

class PrintHistoryInitial extends PrintHistoryState {
  const PrintHistoryInitial();
}

class PrintHistoryLoading extends PrintHistoryState {
  const PrintHistoryLoading();
}

class PrintHistoryLoaded extends PrintHistoryState {
  const PrintHistoryLoaded({
    required this.jobs,
    required this.hasMore,
  });

  final List<PrintJob> jobs;
  final bool hasMore;

  @override
  List<Object?> get props => [jobs, hasMore];
}

class PrintHistoryLoadingMore extends PrintHistoryState {
  const PrintHistoryLoadingMore({required this.jobs});

  final List<PrintJob> jobs;

  @override
  List<Object?> get props => [jobs];
}

class PrintHistoryError extends PrintHistoryState {
  const PrintHistoryError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
