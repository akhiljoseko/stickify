import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base class for all states emitted by the preview cubit.
sealed class PreviewState extends Equatable {
  /// Creates a [PreviewState] instance.
  const PreviewState();

  @override
  List<Object?> get props => [];
}

/// State emitted when the template is being loaded from the database.
class PreviewLoading extends PreviewState {
  /// Creates a [PreviewLoading] instance.
  const PreviewLoading();
}

/// State emitted when the template details are successfully loaded and ready for preview.
class PreviewLoaded extends PreviewState {
  /// Creates a [PreviewLoaded] instance with the loaded [template].
  const PreviewLoaded(this.template);

  /// The template representation that was loaded.
  final LabelTemplate template;

  @override
  List<Object?> get props => [template];
}

/// State emitted when the template is currently being finalized in the database.
class PreviewFinalizing extends PreviewState {
  /// Creates a [PreviewFinalizing] instance.
  const PreviewFinalizing();
}

/// State emitted when the template has been successfully finalized.
class PreviewFinalized extends PreviewState {
  /// Creates a [PreviewFinalized] instance.
  const PreviewFinalized();
}

/// State emitted when an error occurs while loading or finalizing the template.
class PreviewError extends PreviewState {
  /// Creates a [PreviewError] instance with an error [message].
  const PreviewError(this.message);

  /// Message describing the error.
  final String message;

  @override
  List<Object?> get props => [message];
}
