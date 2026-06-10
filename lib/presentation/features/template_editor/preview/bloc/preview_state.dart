import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

sealed class PreviewState extends Equatable {
  const PreviewState();

  @override
  List<Object?> get props => [];
}

class PreviewLoading extends PreviewState {
  const PreviewLoading();
}

class PreviewLoaded extends PreviewState {
  const PreviewLoaded(this.template);

  final LabelTemplate template;

  @override
  List<Object?> get props => [template];
}

class PreviewFinalizing extends PreviewState {
  const PreviewFinalizing();
}

class PreviewFinalized extends PreviewState {
  const PreviewFinalized();
}

class PreviewError extends PreviewState {
  const PreviewError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
