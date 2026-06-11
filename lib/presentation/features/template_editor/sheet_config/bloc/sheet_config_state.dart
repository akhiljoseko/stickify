import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base state class for paper sheet layout configuration setup.
sealed class SheetConfigState extends Equatable {
  /// Base constructor.
  const SheetConfigState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the sheet configuration screen.
class SheetConfigInitial extends SheetConfigState {
  /// Creates a [SheetConfigInitial] state.
  const SheetConfigInitial();
}

/// Loading state indicating layout data is being initialized or fetched.
class SheetConfigLoading extends SheetConfigState {
  /// Creates a [SheetConfigLoading] state.
  const SheetConfigLoading();
}

/// Active editing state enclosing the active [SheetConfig] parameter values.
class SheetConfigEditing extends SheetConfigState {
  /// Creates a [SheetConfigEditing] state.
  const SheetConfigEditing(this.config);

  /// The active sheet configuration properties.
  final SheetConfig config;

  @override
  List<Object?> get props => [config];
}

/// Transition state during configuration save.
class SheetConfigSaving extends SheetConfigState {
  /// Creates a [SheetConfigSaving] state.
  const SheetConfigSaving();
}

/// Success state indicating the sheet layout was saved successfully.
class SheetConfigSaved extends SheetConfigState {
  /// Creates a [SheetConfigSaved] state.
  const SheetConfigSaved(this.templateId);

  /// The modified template identifier.
  final String templateId;

  @override
  List<Object?> get props => [templateId];
}

/// Error state conveying database or layout errors.
class SheetConfigError extends SheetConfigState {
  /// Creates a [SheetConfigError] state.
  const SheetConfigError(this.message);

  /// The error description message.
  final String message;

  @override
  List<Object?> get props => [message];
}
