// prefer_int_literals suppressed for Duration clarity.
// ignore_for_file: comment_references
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

part 'recent_print_jobs_state.dart';

/// Manages the state for the "Recently Printed Labels" carousel section
/// of the Dashboard screen.
///
/// ## State Lifecycle
/// ```text
/// Initial ──(loadRecentJobs)──▶ Loading ──(success)──▶ Loaded
///                                        └──(failure)──▶ Error
///          Error ──(loadRecentJobs retry)──▶ Loading
/// ```
///
/// ## Mock Phase
/// The cubit delegates to [PrintJobRepository], which is currently backed
/// by [MockPrintJobRepository]. No real network calls are made. To switch
/// to a real backend, only the concrete repository implementation needs to
/// change — this cubit is untouched.
class RecentPrintJobsCubit extends Cubit<RecentPrintJobsState> {
  /// Creates a [RecentPrintJobsCubit] instance.
  RecentPrintJobsCubit({required PrintJobRepository printJobRepository})
      : _repository = printJobRepository,
        super(const RecentPrintJobsInitial());

  final PrintJobRepository _repository;

  /// Fetches the most recent print jobs and emits the appropriate state.
  ///
  /// Safe to call multiple times (e.g., on pull-to-refresh). Always
  /// transitions through [RecentPrintJobsLoading] first.
  Future<void> loadRecentJobs() async {
    emit(const RecentPrintJobsLoading());
    final result = await _repository.getRecentJobs(limit: 5);
    switch (result) {
      case Success(value: final jobs):
        emit(RecentPrintJobsLoaded(jobs: jobs));
      case Failure(error: final err):
        emit(RecentPrintJobsError(message: err.message));
    }
  }
}
