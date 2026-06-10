import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

abstract class PrintWorkflowState extends Equatable {
  const PrintWorkflowState();

  @override
  List<Object?> get props => [];
}

class PrintWorkflowInitial extends PrintWorkflowState {
  const PrintWorkflowInitial();
}

class PrintWorkflowLoading extends PrintWorkflowState {
  const PrintWorkflowLoading();
}

class PrintWorkflowLoaded extends PrintWorkflowState {
  const PrintWorkflowLoaded({
    required this.product,
    required this.variant,
    required this.templates,
    this.selectedTemplate,
    this.quantity = 20,
    this.selectedPrinter = 'Zebra ZT411-A (Default)',
    this.disabledSlots = const {},
  });

  final Product product;
  final ProductVariant variant;
  final List<LabelTemplate> templates;
  final LabelTemplate? selectedTemplate;
  final int quantity;
  final String selectedPrinter;
  final Set<int> disabledSlots;

  PrintWorkflowLoaded copyWith({
    Product? product,
    ProductVariant? variant,
    List<LabelTemplate>? templates,
    LabelTemplate? Function()? selectedTemplate,
    int? quantity,
    String? selectedPrinter,
    Set<int>? disabledSlots,
  }) {
    return PrintWorkflowLoaded(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate != null ? selectedTemplate() : this.selectedTemplate,
      quantity: quantity ?? this.quantity,
      selectedPrinter: selectedPrinter ?? this.selectedPrinter,
      disabledSlots: disabledSlots ?? this.disabledSlots,
    );
  }

  @override
  List<Object?> get props => [
        product,
        variant,
        templates,
        selectedTemplate,
        quantity,
        selectedPrinter,
        disabledSlots,
      ];
}

class PrintWorkflowSubmitting extends PrintWorkflowState {
  const PrintWorkflowSubmitting({required this.loadedState});

  final PrintWorkflowLoaded loadedState;

  @override
  List<Object?> get props => [loadedState];
}

class PrintWorkflowSuccess extends PrintWorkflowState {
  const PrintWorkflowSuccess({required this.printJob});

  final PrintJob printJob;

  @override
  List<Object?> get props => [printJob];
}

class PrintWorkflowError extends PrintWorkflowState {
  const PrintWorkflowError({required this.message});

  final String message;

  @override
  List<Object?> get props => [message];
}
