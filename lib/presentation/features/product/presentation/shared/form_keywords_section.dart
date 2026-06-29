import 'package:flutter/material.dart';
import 'package:stickify/app/theme.dart';

class FormKeywordsSection extends StatelessWidget {
  const FormKeywordsSection({
    required this.keywordController,
    required this.keywords,
    required this.onAddKeyword,
    required this.onRemoveKeyword,
    required this.isMobile,
    super.key,
  });

  final TextEditingController keywordController;
  final List<String> keywords;
  final VoidCallback onAddKeyword;
  final ValueChanged<int> onRemoveKeyword;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.tag_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Search Keywords', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: keywordController,
                    decoration: const InputDecoration(
                      labelText: 'Add Keyword',
                      hintText: 'e.g. Sugar-free',
                    ),
                    onSubmitted: (_) => onAddKeyword(),
                  ),
                ),
                const SizedBox(width: 12),
                if (isMobile)
                  ElevatedButton.icon(
                    onPressed: onAddKeyword,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  )
                else
                  IconButton(
                    onPressed: onAddKeyword,
                    icon: const Icon(Icons.add_circle_outline),
                    tooltip: 'Add Keyword',
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
            if (keywords.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(keywords.length, (index) {
                  final kw = keywords[index];
                  return InputChip(
                    label: Text(kw),
                    onDeleted: () => onRemoveKeyword(index),
                    backgroundColor: colorScheme.containerLow,
                    side: BorderSide(color: colorScheme.outlineVariant),
                  );
                }),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
