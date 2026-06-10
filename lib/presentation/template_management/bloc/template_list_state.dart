import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

sealed class TemplateListState extends Equatable {
  const TemplateListState();

  @override
  List<Object?> get props => [];
}

class TemplateListInitial extends TemplateListState {
  const TemplateListInitial();
}

class TemplateListLoading extends TemplateListState {
  const TemplateListLoading();
}

class TemplateListLoaded extends TemplateListState {
  const TemplateListLoaded(this.templates);

  final List<LabelTemplate> templates;

  @override
  List<Object?> get props => [templates];
}

class TemplateListError extends TemplateListState {
  const TemplateListError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
