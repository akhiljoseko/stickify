import 'package:flutter/material.dart';
import 'package:responsive_framework/responsive_framework.dart';

/// A responsive search bar component matching the Stitch design specifications.
///
/// On Desktop and Tablet viewports, it displays a fluid input field constrained
/// to a maximum width of 400px.
///
/// On Mobile viewports, it collapses into a single search icon button. Tapping
/// the icon opens a full-screen search overlay.
class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final bp = ResponsiveBreakpoints.of(context);
    final isMobile = bp.isMobile;

    if (isMobile) {
      return IconButton(
        icon: Icon(
          Icons.search,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        tooltip: 'Search',
        onPressed: () => _showMobileSearchOverlay(context),
      );
    }

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Icon(Icons.search, size: 20),
            ),
            Expanded(
              child: TextField(
                style: Theme.of(context).textTheme.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'Search products, SKUs, or templates...',
                  hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMobileSearchOverlay(BuildContext context) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Search',
      pageBuilder: (context, _, _) {
        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: TextField(
              autofocus: true,
              style: Theme.of(context).textTheme.bodyLarge,
              decoration: InputDecoration(
                hintText: 'Search products, SKUs, or templates...',
                hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                border: InputBorder.none,
              ),
              onSubmitted: (val) {
                // Handle search query submission
                Navigator.pop(context);
              },
            ),
            shape: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recent Searches',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 16),
                _buildRecentSearchItem(context, 'BEV-CB-ORG-12'),
                _buildRecentSearchItem(context, 'Gaming Headset'),
                _buildRecentSearchItem(context, 'Station #02'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentSearchItem(BuildContext context, String query) {
    return ListTile(
      leading: const Icon(Icons.history, size: 20),
      title: Text(query),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        // Execute search
        Navigator.pop(context);
      },
    );
  }
}
