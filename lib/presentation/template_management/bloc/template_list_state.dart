import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base class for all states emitted by the template list cubit.
sealed class TemplateListState extends Equatable {
  /// Creates a [TemplateListState] instance.
  const TemplateListState();

  @override
  List<Object?> get props => [];
}

/// Initial template list state.
class TemplateListInitial extends TemplateListState {
  /// Creates a [TemplateListInitial] instance.
  const TemplateListInitial();
}

/// State emitted when the template list is loading.
class TemplateListLoading extends TemplateListState {
  /// Creates a [TemplateListLoading] instance.
  const TemplateListLoading();
}

/// State emitted when the list of templates is successfully loaded.
class TemplateListLoaded extends TemplateListState {
  /// Creates a [TemplateListLoaded] instance with a list of [templates].
  const TemplateListLoaded(this.templates);

  /// The list of loaded label templates.
  final List<LabelTemplate> templates;

  @override
  List<Object?> get props => [templates];
}

/// State emitted when an error occurs while managing templates.
class TemplateListError extends TemplateListState {
  /// Creates a [TemplateListError] instance.
  const TemplateListError(this.message);

  /// Message describing the error.
  final String message;

  @override
  List<Object?> get props => [message];
}
