import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

sealed class SheetConfigState extends Equatable {
  const SheetConfigState();

  @override
  List<Object?> get props => [];
}

class SheetConfigInitial extends SheetConfigState {
  const SheetConfigInitial();
}

class SheetConfigLoading extends SheetConfigState {
  const SheetConfigLoading();
}

class SheetConfigEditing extends SheetConfigState {
  const SheetConfigEditing(this.config);

  final SheetConfig config;

  @override
  List<Object?> get props => [config];
}

class SheetConfigSaving extends SheetConfigState {
  const SheetConfigSaving();
}

class SheetConfigSaved extends SheetConfigState {
  const SheetConfigSaved(this.templateId);

  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

class SheetConfigError extends SheetConfigState {
  const SheetConfigError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
