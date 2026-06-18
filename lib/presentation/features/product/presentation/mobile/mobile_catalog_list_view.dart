import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/presentation/mobile/mobile_product_card.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class MobileCatalogListView extends StatelessWidget {
  const MobileCatalogListView({required this.state, super.key});

  final ProductPageLoaded state;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return AdaptiveScrollWrapper(
      builder: (context, controller) => CustomScrollView(
        controller: controller,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Product Assets',
                      style: textTheme.displayLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse and manage your active product items.',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (val) => context.read<ProductCubit>().applyFilter(query: val),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'Search products...',
                            fillColor: colorScheme.containerLow,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: (state.categoryFilter == null || state.categoryFilter!.isEmpty) ? 'All' : state.categoryFilter!,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            fillColor: colorScheme.containerLow,
                          ),
                          items: [
                            const DropdownMenuItem(value: 'All', child: Text('All Categories')),
                            ...ProductCategories.all.map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
                            )),
                          ],
                          onChanged: (val) {
                            final categoryVal = (val == null || val == 'All') ? '' : val;
                            context.read<ProductCubit>().applyFilter(category: categoryVal);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                if (state.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 64),
                    child: Center(
                      child: Text('No products found.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                    ),
                  )
                else
                  ...state.items.map((product) => MobileProductCard(product: product)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
