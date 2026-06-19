import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/catalog_filter_bar.dart';
import 'package:stickify/presentation/features/product/presentation/desktop/product_desktop_table.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_shared_widgets.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class CatalogListView extends StatelessWidget {
  const CatalogListView({required this.state, super.key});

  final ProductPageLoaded state;

  EdgeInsets _padding(BuildContext context) =>
      AdaptiveValue<EdgeInsets>(
        context,
        defaultValue: const EdgeInsets.all(16),
        tablet: const EdgeInsets.all(24),
        desktop: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
      ).value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final pad = _padding(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1440),
        child: AdaptiveScrollWrapper(
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: pad.left, right: pad.right, top: pad.top),
                  child: Row(
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
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: pad.left, vertical: 24),
                  child: const CatalogFilterBar(),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(left: pad.left, right: pad.right),
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.containerLow,
                      border: Border(
                        bottom: BorderSide(color: colorScheme.outlineVariant),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        const SizedBox(width: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 4,
                          child: Text(
                            'ASSET',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'SKU / ID',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 3,
                          child: Text(
                            'CATEGORY',
                            style: textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                        Builder(
                          builder: (context) {
                            final bp = ResponsiveBreakpoints.of(context);
                            final hasSpace = bp.breakpoint.name == AppBreakpoints.desktop ||
                                bp.breakpoint.name == AppBreakpoints.fourK;
                            final actionWidth = hasSpace ? 96.0 : 48.0;
                            return SizedBox(
                              width: actionWidth,
                              child: const Text('', textAlign: TextAlign.right),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.only(left: pad.left, right: pad.right, bottom: pad.bottom),
                sliver: PagedSliverList<int, Product>(
                  state: state.pagingState,
                  fetchNextPage: () => context.read<ProductCubit>().fetchNextPage(),
                  builderDelegate: PagedChildBuilderDelegate<Product>(
                    itemBuilder: (context, product, index) => DesktopProductTableRow(
                      product: product,
                      onViewDetails: () => context.read<ProductCubit>().setSubView(ProductDetailView(product)),
                    ),
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
                    noItemsFoundIndicatorBuilder: (_) => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 64),
                      child: EmptyCatalogState(),
                    ),
                    firstPageErrorIndicatorBuilder: (_) => Padding(
                      padding: const EdgeInsets.all(32),
                      child: Center(
                        child: Text(
                          'Failed to load products. Pull down to retry.',
                          style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
