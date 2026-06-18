import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/catalog_filter_bar.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/product_desktop_table.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class CatalogListView extends StatelessWidget {
  const CatalogListView({required this.state, super.key});

  final ProductPageLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: AdaptiveScrollWrapper(
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              SliverPadding(
                padding: AdaptiveValue<EdgeInsets>(
                  context,
                  defaultValue: const EdgeInsets.all(16),
                  tablet: const EdgeInsets.all(24),
                  desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                ).value,
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Product Assets',
                                style: textTheme.displayLarge,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Manage SKU labels and print specifications across active assets.',
                                style: textTheme.bodyMedium?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => context.read<ProductCubit>().setSubView(const ProductCreateView()),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Product'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const CatalogFilterBar(),
                    const SizedBox(height: 20),
                    ProductDesktopTable(products: state.items),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
