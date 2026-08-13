import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/order_label_print/cubits/order_label_print_state.dart';

/// Drives the wizard steps (1-3) for selecting templates, browsing products, and configuring the order batch.
class OrderLabelPrintCubit extends Cubit<OrderLabelPrintState> {
  /// Creates an [OrderLabelPrintCubit].
  OrderLabelPrintCubit({
    required TemplateRepository templateRepository,
    required ProductRepository productRepository,
    required PrinterDiscoveryService printerDiscoveryService,
  })  : _templateRepository = templateRepository,
        _productRepository = productRepository,
        _printerDiscoveryService = printerDiscoveryService,
        super(const OrderLabelPrintState());

  final TemplateRepository _templateRepository;
  final ProductRepository _productRepository;
  final PrinterDiscoveryService _printerDiscoveryService;

  /// Initializes templates catalog, product catalog, and available printers.
  Future<void> init() async {
    emit(state.copyWith(isLoading: true, errorMessage: () => null));

    final templatesResult = await _templateRepository.fetchTemplates();
    final productsResult = await _productRepository.getAllProducts();
    final printers = await _printerDiscoveryService.getAvailablePrinters();

    List<LabelTemplate> templates = [];
    if (templatesResult is Success<List<LabelTemplate>, AppError>) {
      templates = templatesResult.value;
    }

    List<Product> products = [];
    if (productsResult is Success<List<Product>, AppError>) {
      products = productsResult.value;
    }

    final defaultPrinter = printers.firstWhere(
      (p) => p.isDefault,
      orElse: () => printers.isNotEmpty ? printers.first : const PrinterDevice(name: 'No Printer Found', url: ''),
    );

    LabelTemplate? defaultTemplate;
    if (templates.isNotEmpty) {
      defaultTemplate = templates.first;
    }

    emit(
      state.copyWith(
        isLoading: false,
        templates: templates,
        selectedTemplate: () => defaultTemplate,
        products: products,
        filteredProducts: products,
        availablePrinters: printers,
        selectedPrinter: () => defaultPrinter,
      ),
    );
  }

  /// Refreshes product catalog from repository (e.g. after a variant detail edit) and updates running batch items.
  Future<void> refreshProductCatalog([Product? updatedProduct, ProductVariant? oldVariant, ProductVariant? updatedVariant]) async {
    final productsResult = await _productRepository.getAllProducts();
    if (productsResult is Success<List<Product>, AppError>) {
      final products = productsResult.value;
      final filtered = _filterProductsList(products, state.searchQuery);

      List<PrintableItem> updatedItems = List<PrintableItem>.from(state.items);
      if (updatedProduct != null && updatedVariant != null) {
        final targetSku = oldVariant?.sku ?? updatedVariant.sku;
        final existingIndex = updatedItems.indexWhere(
          (item) => item.product.id == updatedProduct.id && item.variant.sku == targetSku,
        );

        if (existingIndex >= 0) {
          final currentQty = updatedItems[existingIndex].quantity;
          updatedItems[existingIndex] = PrintableItem(
            product: updatedProduct,
            variant: updatedVariant,
            quantity: currentQty,
          );
        }
      }

      emit(
        state.copyWith(
          products: products,
          filteredProducts: filtered,
          items: updatedItems,
        ),
      );
    }
  }

  /// Sets the active label template.
  void selectTemplate(LabelTemplate template) {
    emit(state.copyWith(selectedTemplate: () => template));
  }

  /// Updates active printer device.
  void updatePrinter(PrinterDevice printer) {
    emit(state.copyWith(selectedPrinter: () => printer));
  }

  /// Sets active wizard step directly.
  void setStep(OrderLabelPrintStep step) {
    emit(state.copyWith(step: step, errorMessage: () => null));
  }

  /// Navigates to next step if validation passes.
  bool goToNextStep() {
    switch (state.step) {
      case OrderLabelPrintStep.templateSelection:
        if (state.selectedTemplate == null) {
          emit(state.copyWith(errorMessage: () => 'Please select a label template to continue.'));
          return false;
        }
        emit(state.copyWith(step: OrderLabelPrintStep.variantSelection, errorMessage: () => null));
        return true;

      case OrderLabelPrintStep.variantSelection:
        if (state.items.isEmpty) {
          emit(state.copyWith(errorMessage: () => 'Please add at least one product variant to your order batch.'));
          return false;
        }
        emit(state.copyWith(step: OrderLabelPrintStep.printPreview, errorMessage: () => null));
        return true;

      case OrderLabelPrintStep.printPreview:
        return true;
    }
  }

  /// Navigates to previous step.
  void goToPreviousStep() {
    switch (state.step) {
      case OrderLabelPrintStep.templateSelection:
        break;
      case OrderLabelPrintStep.variantSelection:
        emit(state.copyWith(step: OrderLabelPrintStep.templateSelection, errorMessage: () => null));
      case OrderLabelPrintStep.printPreview:
        emit(state.copyWith(step: OrderLabelPrintStep.variantSelection, errorMessage: () => null));
    }
  }

  /// Filters product catalog by name, SKU, or keywords.
  void updateSearchQuery(String query) {
    final filtered = _filterProductsList(state.products, query);
    emit(state.copyWith(searchQuery: query, filteredProducts: filtered));
  }

  List<Product> _filterProductsList(List<Product> products, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return products;

    return products.where((p) {
      final nameMatch = p.name.toLowerCase().contains(trimmed);
      final skuMatch = p.sku.toLowerCase().contains(trimmed);
      final variantMatch = p.variants.any(
        (v) => v.name.toLowerCase().contains(trimmed) || v.sku.toLowerCase().contains(trimmed),
      );
      return nameMatch || skuMatch || variantMatch;
    }).toList();
  }

  /// Adds a variant to running batch or accumulates quantity if already added.
  void addOrUpdateItem(Product product, ProductVariant variant, int quantity) {
    if (quantity <= 0) return;

    final existingIndex = state.items.indexWhere(
      (item) => item.product.id == product.id && item.variant.sku == variant.sku,
    );

    final updatedItems = List<PrintableItem>.from(state.items);
    if (existingIndex >= 0) {
      final currentQty = updatedItems[existingIndex].quantity;
      updatedItems[existingIndex] = PrintableItem(
        product: product,
        variant: variant,
        quantity: currentQty + quantity,
      );
    } else {
      updatedItems.add(
        PrintableItem(
          product: product,
          variant: variant,
          quantity: quantity,
        ),
      );
    }

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }

  /// Updates quantity of an item at [index]. If quantity <= 0, removes the item.
  void updateItemQuantity(int index, int quantity) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = List<PrintableItem>.from(state.items);
    if (quantity <= 0) {
      updatedItems.removeAt(index);
    } else {
      final item = updatedItems[index];
      updatedItems[index] = PrintableItem(
        product: item.product,
        variant: item.variant,
        quantity: quantity,
      );
    }

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }

  /// Removes an item at [index].
  void removeItem(int index) {
    if (index < 0 || index >= state.items.length) return;

    final updatedItems = List<PrintableItem>.from(state.items);
    updatedItems.removeAt(index);

    emit(state.copyWith(items: updatedItems, disabledSlots: const {}, errorMessage: () => null));
  }
}
