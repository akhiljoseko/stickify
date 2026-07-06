import 'package:flutter/material.dart';
import 'package:stickify/app/theme.dart';

class ProductDetailKeywordsCard extends StatelessWidget {
  const ProductDetailKeywordsCard({
    required this.keywords,
    super.key,
  });

  final List<String> keywords;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Search Keywords', style: textTheme.titleSmall),
            const Divider(),
            if (keywords.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  'No search keywords listed.',
                  style: textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: keywords
                    .map((kw) => Chip(
                          label: Text(kw),
                          backgroundColor: colorScheme.containerLow,
                          side: BorderSide(color: colorScheme.outlineVariant),
                        ))
                    .toList(),
              ),
          ],
        ),
      ),
    );
  }
}
