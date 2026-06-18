import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/mobile/mobile_catalog_list_view.dart';
import 'package:stickify/presentation/features/product/presentation/mobile/mobile_product_detail_panel.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_form_view.dart';

/// Mobile-specific Product catalogue Screen.
/// Provides browsing product catalogue list/details, variant price editing, and full product creation/editing.
class MobileProductManagementScreen extends StatelessWidget {
  const MobileProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final cubitState = context.watch<ProductCubit>().state;
    final showFab = cubitState is ProductPageLoaded && cubitState.subView is ProductCatalogView;
    final formKey = GlobalKey<ProductFormViewState>();

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: showFab
          ? FloatingActionButton(
              onPressed: () => context.read<ProductCubit>().setSubView(const ProductCreateView()),
              child: const Icon(Icons.add),
            )
          : null,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductPageError) {
            context.read<NotificationService>().showError(state.message);
          }
        },
        builder: (context, state) {
          if (state is ProductPageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ProductPageError && state.message.isNotEmpty) {
            return ErrorView(
              message: state.message,
              onRetry: () => context.read<ProductCubit>().fetchPage(pageKey: 0, pageSize: 20),
              onBack: () => Navigator.of(context).pop(),
            );
          }

          if (state is ProductFormSubmitting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Saving product...'),
                ],
              ),
            );
          }

          if (state is ProductPageLoaded) {
            switch (state.subView) {
              case ProductDetailView(:final product):
                return MobileProductDetailPanel(
                  product: product,
                  onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                );
              case ProductCreateView():
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    ),
                    title: const Text('Add Product'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Save Product',
                        onPressed: () => formKey.currentState?.saveForm(),
                      ),
                    ],
                  ),
                  body: ProductFormView(
                    key: formKey,
                    onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                  ),
                );
              case ProductEditView(:final product):
                return Scaffold(
                  appBar: AppBar(
                    leading: IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    ),
                    title: const Text('Edit Product'),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.check),
                        tooltip: 'Save Product',
                        onPressed: () => formKey.currentState?.saveForm(),
                      ),
                    ],
                  ),
                  body: ProductFormView(
                    key: formKey,
                    product: product,
                    onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                    onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                  ),
                );
              case ProductCatalogView():
                return MobileCatalogListView(state: state);
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
