import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:stickify/app/theme.dart';
import 'package:stickify/core/utils/image_utils.dart';
import 'package:stickify/domain/entities/product.dart';
import 'package:stickify/presentation/features/product/bloc/product_cubit.dart';
import 'package:stickify/presentation/features/product/bloc/product_sub_view.dart';
import 'package:stickify/presentation/features/product/presentation/shared/product_shared_widgets.dart';

class ProductDesktopTable extends StatelessWidget {
  const ProductDesktopTable({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    if (products.isEmpty) {
      return const EmptyCatalogState();
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.containerLow,
              border: Border(
                bottom: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
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
                const SizedBox(
                  width: 48,
                  child: Text('', textAlign: TextAlign.right),
                ),
              ],
            ),
          ),
          Column(
            children: products
                .map(
                  (product) => DesktopProductTableRow(
                    product: product,
                    onViewDetails: () => context
                        .read<ProductCubit>()
                        .setSubView(ProductDetailView(product)),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class DesktopProductTableRow extends StatefulWidget {
  const DesktopProductTableRow({
    required this.product,
    required this.onViewDetails,
    super.key,
  });

  final Product product;
  final VoidCallback onViewDetails;

  @override
  State<DesktopProductTableRow> createState() => _DesktopProductTableRowState();
}

class _DesktopProductTableRowState extends State<DesktopProductTableRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bp = ResponsiveBreakpoints.of(context);
    final enableHoverEffects = !bp.isMobile && !bp.isTablet;

    final rowBgColor = _isHovered
        ? colorScheme.containerLow
        : colorScheme.containerLowest;

    return MouseRegion(
      onEnter: (_) {
        if (enableHoverEffects) setState(() => _isHovered = true);
      },
      onExit: (_) {
        if (enableHoverEffects) setState(() => _isHovered = false);
      },
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        transform: Matrix4.translationValues(_isHovered ? 4 : 0, 0, 0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: rowBgColor,
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant, width: 0.5),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: colorScheme.container,
                image:
                    widget.product.imageUrl != null &&
                        widget.product.imageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: resolveImageProvider(widget.product.imageUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child:
                  widget.product.imageUrl == null ||
                      widget.product.imageUrl!.isEmpty
                  ? Icon(
                      Icons.inventory_2_outlined,
                      size: 16,
                      color: colorScheme.primary,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 4,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.product.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                widget.product.sku,
                style: textTheme.labelMedium?.copyWith(
                  fontFamily: 'JetBrains Mono',
                ),
              ),
            ),
            Expanded(
              flex: 3,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: colorScheme.outlineVariant),
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.2,
                      ),
                    ),
                    child: Text(
                      widget.product.category ?? 'N/A',
                      style: textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: 48,
              child: IconButton(
                onPressed: widget.onViewDetails,
                icon: const Icon(Icons.visibility_outlined, size: 20),
                tooltip: 'View Details',
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
