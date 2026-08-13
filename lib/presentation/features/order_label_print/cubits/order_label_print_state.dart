import 'package:equatable/equatable.dart';
import 'package:stickify/domain/domain.dart';

/// Steps in the Order Label Printing Wizard.
enum OrderLabelPrintStep {
  /// Step 1: Template selection
  templateSelection,

  /// Step 2: Variant & quantity selection
  variantSelection,

  /// Step 3: Order confirmation / review list
  confirmation,

  /// Step 4: Final print preview & printer parameters
  printPreview,
}

/// State for the Order Label Printing Wizard.
class OrderLabelPrintState extends Equatable {
  /// Creates an [OrderLabelPrintState].
  const OrderLabelPrintState({
    this.step = OrderLabelPrintStep.templateSelection,
    this.isLoading = false,
    this.isSubmitting = false,
    this.isPrintSuccess = false,
    this.templates = const [],
    this.selectedTemplate,
    this.products = const [],
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.items = const [],
    this.availablePrinters = const [],
    this.selectedPrinter,
    this.selectedPrinterProfile,
    this.selectedTrayProfile,
    this.compatibilityResult,
    this.disabledSlots = const {},
    this.printFromBottom = false,
    this.reverseSheetOrder = false,
    this.manufacturingDate,
    this.errorMessage,
    this.successMessage,
  });

  /// Current wizard step.
  final OrderLabelPrintStep step;

  /// Whether initial data loading is in progress.
  final bool isLoading;

  /// Whether printing/compilation is currently submitting.
  final bool isSubmitting;

  /// Flag set to true upon successful print completion (for post-print exit navigation).
  final bool isPrintSuccess;

  /// Catalog of label templates.
  final List<LabelTemplate> templates;

  /// Selected label template.
  final LabelTemplate? selectedTemplate;

  /// Full product catalog.
  final List<Product> products;

  /// Filtered product catalog based on search query.
  final List<Product> filteredProducts;

  /// Active product search query.
  final String searchQuery;

  /// Running batch order items.
  final List<PrintableItem> items;

  /// Available system printers.
  final List<PrinterDevice> availablePrinters;

  /// Currently selected printer device.
  final PrinterDevice? selectedPrinter;

  /// Selected printer profile (matched from database).
  final PrinterProfile? selectedPrinterProfile;

  /// Selected tray profile for calibration/compatibility checks.
  final PrinterTrayProfile? selectedTrayProfile;

  /// Cached compatibility check result.
  final CompatibilityAnalysisResult? compatibilityResult;

  /// Set of disabled slot indices across the batch sheet layout.
  final Set<int> disabledSlots;

  /// Whether to print active slots starting from the bottom of the sheet.
  final bool printFromBottom;

  /// Whether physical sheets print in reverse order.
  final bool reverseSheetOrder;

  /// Global manufacturing date for dynamic token resolution.
  final DateTime? manufacturingDate;

  /// Operational error message, if any.
  final String? errorMessage;

  /// Success message on completion.
  final String? successMessage;

  /// Total active label count across all items in the batch.
  int get totalQuantity => items.fold<int>(0, (sum, item) => sum + item.quantity);

  /// Total sheet count required for totalQuantity given current template and disabled slots.
  int get totalSheets {
    final template = selectedTemplate;
    final sheetConfig = template?.sheetConfig;
    if (template == null || sheetConfig == null || totalQuantity == 0) return 0;

    final slotsPerSheet = sheetConfig.columns * sheetConfig.rows;
    if (slotsPerSheet == 0) return 0;

    var currentSlot = 0;
    var printedCount = 0;

    while (printedCount < totalQuantity) {
      if (!disabledSlots.contains(currentSlot)) {
        printedCount++;
      }
      currentSlot++;
    }

    return (currentSlot / slotsPerSheet).ceil();
  }

  /// Creates a copy of [OrderLabelPrintState] with updated values.
  OrderLabelPrintState copyWith({
    OrderLabelPrintStep? step,
    bool? isLoading,
    bool? isSubmitting,
    bool? isPrintSuccess,
    List<LabelTemplate>? templates,
    LabelTemplate? Function()? selectedTemplate,
    List<Product>? products,
    List<Product>? filteredProducts,
    String? searchQuery,
    List<PrintableItem>? items,
    List<PrinterDevice>? availablePrinters,
    PrinterDevice? Function()? selectedPrinter,
    PrinterProfile? Function()? selectedPrinterProfile,
    PrinterTrayProfile? Function()? selectedTrayProfile,
    CompatibilityAnalysisResult? Function()? compatibilityResult,
    Set<int>? disabledSlots,
    bool? printFromBottom,
    bool? reverseSheetOrder,
    DateTime? Function()? manufacturingDate,
    String? Function()? errorMessage,
    String? Function()? successMessage,
  }) {
    return OrderLabelPrintState(
      step: step ?? this.step,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isPrintSuccess: isPrintSuccess ?? this.isPrintSuccess,
      templates: templates ?? this.templates,
      selectedTemplate: selectedTemplate != null ? selectedTemplate() : this.selectedTemplate,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      items: items ?? this.items,
      availablePrinters: availablePrinters ?? this.availablePrinters,
      selectedPrinter: selectedPrinter != null ? selectedPrinter() : this.selectedPrinter,
      selectedPrinterProfile: selectedPrinterProfile != null ? selectedPrinterProfile() : this.selectedPrinterProfile,
      selectedTrayProfile: selectedTrayProfile != null ? selectedTrayProfile() : this.selectedTrayProfile,
      compatibilityResult: compatibilityResult != null ? compatibilityResult() : this.compatibilityResult,
      disabledSlots: disabledSlots ?? this.disabledSlots,
      printFromBottom: printFromBottom ?? this.printFromBottom,
      reverseSheetOrder: reverseSheetOrder ?? this.reverseSheetOrder,
      manufacturingDate: manufacturingDate != null ? manufacturingDate() : this.manufacturingDate,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      successMessage: successMessage != null ? successMessage() : this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
        step,
        isLoading,
        isSubmitting,
        isPrintSuccess,
        templates,
        selectedTemplate,
        products,
        filteredProducts,
        searchQuery,
        items,
        availablePrinters,
        selectedPrinter,
        selectedPrinterProfile,
        selectedTrayProfile,
        compatibilityResult,
        disabledSlots,
        printFromBottom,
        reverseSheetOrder,
        manufacturingDate,
        errorMessage,
        successMessage,
      ];
}
