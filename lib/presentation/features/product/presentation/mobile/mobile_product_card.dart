import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/utils/image_utils.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';

class MobileProductCard extends StatelessWidget {
  const MobileProductCard({required this.product, super.key});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: InkWell(
          onTap: () => context.read<ProductCubit>().setSubView(
            ProductDetailView(product),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6),
                        color: colorScheme.container,
                        image:
                            product.imageUrl != null &&
                                product.imageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: resolveImageProvider(product.imageUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child:
                          product.imageUrl == null || product.imageUrl!.isEmpty
                          ? Icon(
                              Icons.inventory_2_outlined,
                              color: colorScheme.primary,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: textTheme.titleSmall,
                          ),
                          if (product.category != null &&
                              product.category!.isNotEmpty)
                            Text(
                              product.category!,
                              style: textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          const SizedBox(height: 4),
                          Text(
                            product.sku,
                            style: textTheme.labelMedium?.copyWith(
                              fontFamily: 'JetBrains Mono',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
