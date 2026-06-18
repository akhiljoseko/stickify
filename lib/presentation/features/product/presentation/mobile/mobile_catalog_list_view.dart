import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
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
    final pagingState = state.pagingState;

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
                          onChanged: (val) => context.read<ProductCubit>().fetchPage(
                                pageKey: 0,
                                pageSize: 20,
                                query: val.isEmpty ? null : val,
                                category: pagingState.categoryFilter,
                              ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 20),
                            hintText: 'Search products...',
                            fillColor: colorScheme.containerLow,
                          ),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          isExpanded: true,
                          initialValue: (pagingState.categoryFilter == null || pagingState.categoryFilter!.isEmpty) ? 'All' : pagingState.categoryFilter!,
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
                            final categoryVal = (val == null || val == 'All') ? null : val;
                            context.read<ProductCubit>().fetchPage(
                                  pageKey: 0,
                                  pageSize: 20,
                                  query: pagingState.searchQuery,
                                  category: categoryVal,
                                );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ]),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: PagedSliverList<int, Product>(
              state: state.pagingState,
              fetchNextPage: () => context.read<ProductCubit>().fetchNextPage(),
              builderDelegate: PagedChildBuilderDelegate<Product>(
                itemBuilder: (context, product, index) => MobileProductCard(product: product),
                firstPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                newPageProgressIndicatorBuilder: (_) => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                noItemsFoundIndicatorBuilder: (_) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 64),
                  child: Center(
                    child: Text('No products found.', style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline)),
                  ),
                ),
                firstPageErrorIndicatorBuilder: (_) => Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text(
                      'Failed to load products.',
                      style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SliverPadding(
            padding: EdgeInsets.only(bottom: 16),
          ),
        ],
      ),
    );
  }
}
