import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/catalog_list_view.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/product_detail_panel.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_form_view.dart';

class DesktopProductManagementScreen extends StatelessWidget {
  const DesktopProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: BlocConsumer<ProductCubit, ProductState>(
        listener: (context, state) {
          if (state is ProductFormError) {
            context.read<NotificationService>().showError(state.message);
          }
        },
        builder: (context, state) {
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
              case ProductCreateView():
                return ProductFormView(
                  onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                  onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                );
              case ProductEditView(:final product):
                return ProductFormView(
                  product: product,
                  onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                  onSave: (product) => context.read<ProductCubit>().saveProduct(product),
                );
              case ProductDetailView(:final product):
                return ProductDetailPanel(
                  product: product,
                  onBack: () => context.read<ProductCubit>().setSubView(const ProductCatalogView()),
                  onEdit: (product) => context.read<ProductCubit>().setSubView(ProductEditView(product)),
                  onDelete: (id) async {
                    await context.read<ProductCubit>().deleteProduct(id);
                    if (context.mounted) {
                      context.read<ProductCubit>().setSubView(const ProductCatalogView());
                    }
                  },
                );
              case ProductCatalogView():
                return CatalogListView(state: state);
            }
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
