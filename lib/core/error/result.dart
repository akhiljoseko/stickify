import 'package:stickify/core/error/app_error.dart';

/// A sealed class representing either a successful value or a failure error.
sealed class Result<S, F extends AppError> {
  const Result();

  /// Creates a success result containing [value].
  const factory Result.success(S value) = Success<S, F>;

  /// Creates a failure result containing [error].
  const factory Result.failure(F error) = Failure<S, F>;
}

/// A successful [Result] containing the [value] of type [S].
final class Success<S, F extends AppError> extends Result<S, F> {
  const Success(this.value);
  final S value;
}

/// A failed [Result] containing the [error] of type [F].
final class Failure<S, F extends AppError> extends Result<S, F> {
  const Failure(this.error);
  final F error;
}
