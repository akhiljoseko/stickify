import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_state.dart';

class CatalogFilterBar extends StatelessWidget {
  const CatalogFilterBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final state = context.watch<ProductCubit>().state;
    final pagingState = state is ProductPageLoaded ? state.pagingState : null;
    final currentQuery = pagingState?.searchQuery;
    final currentCategory = pagingState?.categoryFilter;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;

            final searchField = TextField(
              onChanged: (val) => context.read<ProductCubit>().fetchPage(
                    pageKey: 0,
                    pageSize: 20,
                    query: val.isEmpty ? null : val,
                    category: currentCategory,
                  ),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search, size: 20),
                hintText: 'Search products by name or SKU...',
                fillColor: colorScheme.containerLow,
              ),
            );

            final categoryDropdown = DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: (currentCategory == null || currentCategory.isEmpty) ? 'All' : currentCategory,
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
                      query: currentQuery,
                      category: categoryVal,
                    );
              },
            );

            if (isCompact) {
              return Column(
                children: [
                  searchField,
                  const SizedBox(height: 12),
                  categoryDropdown,
                ],
              );
            }

            return Row(
              children: [
                Expanded(child: searchField),
                const SizedBox(width: 16),
                SizedBox(width: 220, child: categoryDropdown),
              ],
            );
          },
        ),
      ),
    );
  }
}
