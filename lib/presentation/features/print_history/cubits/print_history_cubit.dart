import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/print_history/cubits/print_history_state.dart';

class PrintHistoryCubit extends Cubit<PrintHistoryState> {
  PrintHistoryCubit({required PrintJobRepository printJobRepository})
      : _repository = printJobRepository,
        super(const PrintHistoryInitial());

  final PrintJobRepository _repository;
  DateTime? _lastPrintedAt;
  static const int _pageSize = 20;

  Future<void> loadFirstPage() async {
    emit(const PrintHistoryLoading());
    _lastPrintedAt = null;
    final result = await _repository.getJobsPaginated();
    switch (result) {
      case Success(value: final jobs):
        _lastPrintedAt = jobs.isNotEmpty ? jobs.last.printedAt : null;
        emit(PrintHistoryLoaded(jobs: jobs, hasMore: jobs.length >= 20));
      case Failure(error: final err):
        emit(PrintHistoryError(message: err.message));
    }
  }

  Future<void> loadNextPage() async {
    final s = state;
    if (s is! PrintHistoryLoaded || !s.hasMore) return;
    if (_lastPrintedAt == null) return;

    emit(PrintHistoryLoadingMore(jobs: s.jobs));
    final result = await _repository.getJobsPaginated(
      before: _lastPrintedAt,
    );
    switch (result) {
      case Success(value: final newJobs):
        _lastPrintedAt = newJobs.isNotEmpty ? newJobs.last.printedAt : null;
        emit(PrintHistoryLoaded(
          jobs: [...s.jobs, ...newJobs],
          hasMore: newJobs.length >= _pageSize,
        ));
      case Failure():
        emit(PrintHistoryLoaded(jobs: s.jobs, hasMore: s.hasMore));
    }
  }
}
