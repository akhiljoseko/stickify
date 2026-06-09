part of 'recent_print_jobs_cubit.dart';

/// Sealed state hierarchy for [RecentPrintJobsCubit].
///
/// Exhaustively switchable via Dart 3 sealed class syntax:
/// ```dart
/// switch (state) {
///   RecentPrintJobsInitial()  => ...
///   RecentPrintJobsLoading()  => ...
///   RecentPrintJobsLoaded()   => ...
///   RecentPrintJobsError()    => ...
/// }
/// ```
sealed class RecentPrintJobsState extends Equatable {
  const RecentPrintJobsState();

  @override
  List<Object?> get props => [];
}

/// Initial state — emitted before any load operation is triggered.
final class RecentPrintJobsInitial extends RecentPrintJobsState {
  const RecentPrintJobsInitial();
}

/// Loading state — emitted while the repository call is in flight.
final class RecentPrintJobsLoading extends RecentPrintJobsState {
  const RecentPrintJobsLoading();
}

/// Loaded state — emitted when jobs have been successfully fetched.
final class RecentPrintJobsLoaded extends RecentPrintJobsState {
  const RecentPrintJobsLoaded({required this.jobs});

  /// The list of recently printed jobs, ordered newest-first.
  final List<PrintJob> jobs;

  @override
  List<Object?> get props => [jobs];
}

/// Error state — emitted when the repository call fails.
final class RecentPrintJobsError extends RecentPrintJobsState {
  const RecentPrintJobsError({required this.message});

  /// Human-readable error description for display in the UI.
  final String message;

  @override
  List<Object?> get props => [message];
}
