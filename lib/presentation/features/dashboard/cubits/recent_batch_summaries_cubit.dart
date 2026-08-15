import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/batch_print_summary.dart';
import 'package:stickify/domain/repositories/batch_print_summary_repository.dart';

/// Base state for [RecentBatchSummariesCubit].
abstract class RecentBatchSummariesState extends Equatable {
  /// Base constructor.
  const RecentBatchSummariesState();

  @override
  List<Object?> get props => [];
}

/// Initial state of recent batch summaries loading.
class RecentBatchSummariesInitial extends RecentBatchSummariesState {
  /// Creates a [RecentBatchSummariesInitial].
  const RecentBatchSummariesInitial();
}

/// Loading state for recent batch summaries.
class RecentBatchSummariesLoading extends RecentBatchSummariesState {
  /// Creates a [RecentBatchSummariesLoading].
  const RecentBatchSummariesLoading();
}

/// Loaded state containing stored batch print summaries within the retention window.
class RecentBatchSummariesLoaded extends RecentBatchSummariesState {
  /// Creates a [RecentBatchSummariesLoaded].
  const RecentBatchSummariesLoaded(this.summaries);

  /// List of recent batch summaries sorted by date descending.
  final List<BatchPrintSummary> summaries;

  @override
  List<Object?> get props => [summaries];
}

/// Error state when fetching batch summaries fails.
class RecentBatchSummariesError extends RecentBatchSummariesState {
  /// Creates a [RecentBatchSummariesError].
  const RecentBatchSummariesError(this.message);

  /// Failure error message.
  final String message;

  @override
  List<Object?> get props => [message];
}

/// Cubit managing recent batch print summaries for the Dashboard.
class RecentBatchSummariesCubit extends Cubit<RecentBatchSummariesState> {
  /// Creates a [RecentBatchSummariesCubit].
  RecentBatchSummariesCubit({
    required BatchPrintSummaryRepository batchPrintSummaryRepository,
  })  : _repository = batchPrintSummaryRepository,
        super(const RecentBatchSummariesInitial());

  final BatchPrintSummaryRepository _repository;

  /// Loads recent batch print summaries stored in the 7-day retention window.
  Future<void> loadSummaries() async {
    emit(const RecentBatchSummariesLoading());
    final result = await _repository.fetchRecentSummaries();

    switch (result) {
      case Failure(error: final err):
        emit(RecentBatchSummariesError(err.message));
      case Success(value: final summaries):
        emit(RecentBatchSummariesLoaded(summaries));
    }
  }
}
