import 'package:flutter/material.dart';
import 'package:stickify/core/core.dart';

class FormStorageSection extends StatelessWidget {
  const FormStorageSection({
    required this.storageController,
    required this.imageUrlController,
    required this.onPickImage,
    required this.onClearImage,
    super.key,
  });

  final TextEditingController storageController;
  final TextEditingController imageUrlController;
  final VoidCallback onPickImage;
  final VoidCallback onClearImage;

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
                Icon(Icons.thermostat_outlined, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Storage & Compliance', style: textTheme.titleSmall),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: storageController,
              decoration: const InputDecoration(labelText: 'Storage Conditions', hintText: 'e.g. Keep refrigerated below 5°C'),
            ),
            const SizedBox(height: 16),
            Text('Product Image', style: textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onPickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                ),
                child: imageUrlController.text.isNotEmpty
                    ? Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image(
                                image: resolveImageProvider(imageUrlController.text),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            right: 8,
                            top: 8,
                            child: CircleAvatar(
                              backgroundColor: colorScheme.surface.withValues(alpha: 0.8),
                              radius: 16,
                              child: IconButton(
                                icon: Icon(Icons.close, size: 16, color: colorScheme.error),
                                onPressed: onClearImage,
                              ),
                            ),
                          ),
                        ],
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined, size: 36, color: colorScheme.primary),
                            const SizedBox(height: 8),
                            Text('Tap to select image', style: textTheme.bodySmall?.copyWith(color: colorScheme.primary)),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
