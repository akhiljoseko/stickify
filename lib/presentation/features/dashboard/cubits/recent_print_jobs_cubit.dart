// Doc-comment code blocks reference framework types outside doc scope;
// prefer_int_literals suppressed for Duration clarity.
// ignore_for_file: missing_code_block_language_in_doc_comment, comment_references
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/domain/entities/print_job.dart';
import 'package:stickify/domain/repositories/print_job_repository.dart';

part 'recent_print_jobs_state.dart';

/// Manages the state for the "Recently Printed Labels" carousel section
/// of the Dashboard screen.
///
/// ## State Lifecycle
/// ```
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
    try {
      final jobs = await _repository.getRecentJobs(limit: 5);
      emit(RecentPrintJobsLoaded(jobs: jobs));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(RecentPrintJobsError(message: e.toString()));
    }
  }
}
