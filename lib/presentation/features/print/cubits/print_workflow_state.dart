import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Base state class for print setup and execution workflow.
abstract class PrintWorkflowState extends Equatable {
  /// Base constructor.
  const PrintWorkflowState();

  @override
  List<Object?> get props => [];
}

/// Initial state of the print workflow.
class PrintWorkflowInitial extends PrintWorkflowState {
  /// Creates a [PrintWorkflowInitial] state.
  const PrintWorkflowInitial();
}

/// Loading state indicating data retrieval (e.g. templates catalog) is in progress.
class PrintWorkflowLoading extends PrintWorkflowState {
  /// Creates a [PrintWorkflowLoading] state.
  const PrintWorkflowLoading();
}

/// Active workflow state carrying the product, selected template, printer configuration, and grid slots.
class PrintWorkflowLoaded extends PrintWorkflowState {
  /// Creates a [PrintWorkflowLoaded] state.
  const PrintWorkflowLoaded({
    required this.product,
    required this.variant,
    required this.templates,
    this.selectedTemplate,
    this.quantity = 20,
    this.availablePrinters = const [],
    this.selectedPrinter,
    this.disabledSlots = const {},
    this.printFromBottom = false,
    this.isQuantityManuallyEdited = false,
    this.selectedPrinterMargins = PrinterMargins.zero,
  });

  /// The active product.
  final Product product;

  /// The active variant of the product.
  final ProductVariant variant;

  /// List of available label templates.
  final List<LabelTemplate> templates;

  /// The currently selected template.
  final LabelTemplate? selectedTemplate;

  /// Label sheet slot index count or quantity to print.
  final int quantity;

  /// List of available system printers.
  final List<PrinterDevice> availablePrinters;

  /// Selected printer device.
  final PrinterDevice? selectedPrinter;

  /// Set of disabled label slot grid indices to skip when compiling.
  final Set<int> disabledSlots;

  /// Whether to print from the bottom of the last sheet.
  final bool printFromBottom;

  /// Whether the user has manually edited the quantity field.
  final bool isQuantityManuallyEdited;

  /// The hardware margins of the selected printer.
  final PrinterMargins selectedPrinterMargins;

  /// Returns a copy of the state with modified fields.
  PrintWorkflowLoaded copyWith({
    Product? product,
    ProductVariant? variant,
    List<LabelTemplate>? templates,
    LabelTemplate? Function()? selectedTemplate,
    int? quantity,
    List<PrinterDevice>? availablePrinters,
    PrinterDevice? Function()? selectedPrinter,
    Set<int>? disabledSlots,
    bool? printFromBottom,
    bool? isQuantityManuallyEdited,
    PrinterMargins? selectedPrinterMargins,
  }) {
    return PrintWorkflowLoaded(
      product: product ?? this.product,
      variant: variant ?? this.variant,
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate != null ? selectedTemplate() : this.selectedTemplate,
      quantity: quantity ?? this.quantity,
      availablePrinters: availablePrinters ?? this.availablePrinters,
      selectedPrinter: selectedPrinter != null ? selectedPrinter() : this.selectedPrinter,
      disabledSlots: disabledSlots ?? this.disabledSlots,
      printFromBottom: printFromBottom ?? this.printFromBottom,
      isQuantityManuallyEdited: isQuantityManuallyEdited ?? this.isQuantityManuallyEdited,
      selectedPrinterMargins: selectedPrinterMargins ?? this.selectedPrinterMargins,
    );
  }

  @override
  List<Object?> get props => [
        product,
        variant,
        templates,
        selectedTemplate,
        quantity,
        availablePrinters,
        selectedPrinter,
        disabledSlots,
        printFromBottom,
        isQuantityManuallyEdited,
        selectedPrinterMargins,
      ];
}

/// Transition state while compiling PDF and sending the layout job to the print service.
class PrintWorkflowSubmitting extends PrintWorkflowState {
  /// Creates a [PrintWorkflowSubmitting] state.
  const PrintWorkflowSubmitting({required this.loadedState});

  /// The active loaded state metadata at the time of submission.
  final PrintWorkflowLoaded loadedState;

  @override
  List<Object?> get props => [loadedState];
}

/// Success state indicating the print job finished compiling and was sent successfully.
class PrintWorkflowSuccess extends PrintWorkflowState {
  /// Creates a [PrintWorkflowSuccess] state.
  const PrintWorkflowSuccess({required this.printJob});

  /// The compiled/sent [PrintJob] entity.
  final PrintJob printJob;

  @override
  List<Object?> get props => [printJob];
}

/// Error state containing a descriptive message of what failed during the print pipeline.
class PrintWorkflowError extends PrintWorkflowState {
  /// Creates a [PrintWorkflowError] state.
  const PrintWorkflowError({required this.message});

  /// The error message.
  final String message;

  @override
  List<Object?> get props => [message];
}
