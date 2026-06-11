import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/utils/adaptive_value.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_cubit.dart';
import 'package:stickify/presentation/template_management/bloc/template_list_state.dart';
import 'package:stickify/presentation/template_management/widgets/template_card.dart';
import 'package:stickify/presentation/template_management/widgets/template_card_skeleton.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

/// Screen presenting the admin interface for managing custom sticker templates.
///
/// Features template creation modal dialogs, cards grid display, and pagination controls.
class TemplateManagementScreen extends StatelessWidget {
  /// Creates a [TemplateManagementScreen] instance.
  const TemplateManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = TemplateListCubit(
          context.read<TemplateRepository>(),
        );
        unawaited(cubit.loadTemplates());
        return cubit;
      },
      child: const _TemplateManagementView(),
    );
  }
}

class _TemplateManagementView extends StatefulWidget {
  const _TemplateManagementView();

  @override
  State<_TemplateManagementView> createState() => _TemplateManagementViewState();
}

class _TemplateManagementViewState extends State<_TemplateManagementView> {
  int _currentPage = 1;
  static const int _itemsPerPage = 8;

  void _showCreateTemplateDialog(BuildContext context) {
    final textController = TextEditingController();

    unawaited(showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Create New Template'),
          content: TextField(
            controller: textController,
            decoration: const InputDecoration(
              hintText: 'Enter template name',
              labelText: 'Template Name',
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = textController.text.trim();
                if (name.isNotEmpty) {
                  Navigator.pop(dialogContext);
                  final cubit = context.read<TemplateListCubit>();
                  final template = await cubit.createNewTemplate(name);
                  if (template != null && context.mounted) {
                    // Navigate to Flow B: Sheet Configuration
                    SheetConfigRoute(templateId: template.id).go(context);
                  }
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Template Management',
                        style: textTheme.displayLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Design and manage your label templates.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Create New Template'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  onPressed: () => _showCreateTemplateDialog(context),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Content
            Expanded(
              child: BlocBuilder<TemplateListCubit, TemplateListState>(
                builder: (context, state) {
                  if (state is TemplateListLoading) {
                    return _buildLoadingGrid(context);
                  }

                  if (state is TemplateListError) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                          const SizedBox(height: 16),
                          Text(state.message, style: textTheme.titleMedium),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => context.read<TemplateListCubit>().loadTemplates(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }

                  if (state is TemplateListLoaded) {
                    final allTemplates = state.templates;
                    if (allTemplates.isEmpty) {
                      return _buildEmptyState(context);
                    }

                    // Paginate
                    final startIndex = (_currentPage - 1) * _itemsPerPage;
                    final paginatedTemplates = allTemplates.skip(startIndex).take(_itemsPerPage).toList();
                    final totalPages = (allTemplates.length / _itemsPerPage).ceil();

                    return Column(
                      children: [
                        Expanded(
                          child: AdaptiveScrollWrapper(
                            builder: (context, scrollController) {
                              final crossAxisCount = AdaptiveValue<int>(
                                context,
                                defaultValue: 1, // mobile
                                tablet: 2,       // tablet
                                desktop: 4,      // desktop/4k
                              ).value;

                              return GridView.builder(
                                controller: scrollController,
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: 16,
                                  mainAxisSpacing: 16,
                                  childAspectRatio: 0.85,
                                ),
                                itemCount: paginatedTemplates.length,
                                itemBuilder: (context, index) {
                                  final template = paginatedTemplates[index];
                                  return TemplateCard(
                                    template: template,
                                    onSelect: () {
                                      // Action to select for printing (e.g. show toast or navigate)
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Selected "${template.name}" for printing'),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                    onEdit: () {
                                      // Flow D: Label Designer
                                      LabelEditorRoute(templateId: template.id).go(context);
                                    },
                                    onDelete: () {
                                      // Delete template
                                      unawaited(context.read<TemplateListCubit>().deleteTemplate(template.id));
                                    },
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        
                        // Pagination Row
                        if (totalPages > 1) ...[
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.chevron_left),
                                onPressed: _currentPage > 1
                                    ? () => setState(() => _currentPage--)
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Text(
                                'Page $_currentPage of $totalPages',
                                style: textTheme.bodyMedium,
                              ),
                              const SizedBox(width: 16),
                              IconButton(
                                icon: const Icon(Icons.chevron_right),
                                onPressed: _currentPage < totalPages
                                    ? () => setState(() => _currentPage++)
                                    : null,
                              ),
                            ],
                          ),
                        ],
                      ],
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingGrid(BuildContext context) {
    final crossAxisCount = AdaptiveValue<int>(
      context,
      defaultValue: 1,
      tablet: 2,
      desktop: 4,
    ).value;

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      itemCount: 8,
      itemBuilder: (context, index) => const TemplateCardSkeleton(),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.layers_outlined,
            size: 64,
            color: colorScheme.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No templates yet',
            style: textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first template to get started.',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.outlineVariant,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create New Template'),
            onPressed: () => _showCreateTemplateDialog(context),
          ),
        ],
      ),
    );
  }
}
