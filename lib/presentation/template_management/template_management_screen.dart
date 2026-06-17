import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/core/core.dart';
import 'package:stickify/core/environment/app_environment.dart';
import 'package:stickify/core/environment/app_experience.dart';
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
  const TemplateManagementScreen({this.initialAction, super.key});

  /// The initial action to perform.
  final String? initialAction;

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
      child: _TemplateManagementView(initialAction: initialAction),
    );
  }
}

class _TemplateManagementView extends StatefulWidget {
  const _TemplateManagementView({this.initialAction});

  final String? initialAction;

  @override
  State<_TemplateManagementView> createState() => _TemplateManagementViewState();
}

class _TemplateManagementViewState extends State<_TemplateManagementView> {
  int _currentPage = 1;
  static const int _itemsPerPage = 8;

  @override
  void initState() {
    super.initState();
    if (widget.initialAction == 'create') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCreateTemplateDialog(context);
      });
    }
  }

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

    final isMobile = context.watch<AppEnvironment>().experience == AppExperience.mobile;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      floatingActionButton: isMobile
          ? FloatingActionButton(
              onPressed: () => _showCreateTemplateDialog(context),
              child: const Icon(Icons.add),
            )
          : null,
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
                if (context.watch<AppEnvironment>().experience != AppExperience.mobile)
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
                    return ErrorView(
                      message: state.message,
                      onRetry: () => context.read<TemplateListCubit>().loadTemplates(),
                      onBack: () => Navigator.of(context).pop(),
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
                              if (isMobile) {
                                return ListView.separated(
                                  controller: scrollController,
                                  itemCount: paginatedTemplates.length,
                                  separatorBuilder: (context, index) => const Divider(height: 1),
                                  itemBuilder: (context, index) {
                                    final template = paginatedTemplates[index];
                                    return _CompactTemplateListTile(
                                      template: template,
                                      onEdit: () {
                                        LabelEditorRoute(templateId: template.id).go(context);
                                      },
                                      onDelete: () {
                                        unawaited(context.read<TemplateListCubit>().deleteTemplate(template.id));
                                      },
                                    );
                                  },
                                );
                              }

                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  final crossAxisCount = (constraints.maxWidth / 280).floor().clamp(1, 6);

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
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = (constraints.maxWidth / 280).floor().clamp(1, 6);

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
      },
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

class _CompactTemplateListTile extends StatelessWidget {
  const _CompactTemplateListTile({
    required this.template,
    required this.onEdit,
    required this.onDelete,
  });

  final LabelTemplate template;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final formattedDate = template.updatedAt != null
        ? DateFormat.yMMMd().add_jm().format(template.updatedAt!)
        : 'Never';

    final sizeDesc = template.stickerConfig != null
        ? '${template.stickerConfig!.widthMm.toStringAsFixed(1)} × ${template.stickerConfig!.heightMm.toStringAsFixed(1)} mm'
        : 'Unconfigured size';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
      ),
      child: Row(
        children: [
          // Left: Compact Thumbnail
          Container(
            width: 72,
            height: 48,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colorScheme.outlineVariant),
            ),
            child: Icon(
              Icons.picture_in_picture_alt_outlined,
              color: colorScheme.primary.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          // Center: Template Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  template.name,
                  style: textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  sizeDesc,
                  style: textTheme.bodySmall?.copyWith(
                    fontFamily: 'JetBrains Mono',
                    color: colorScheme.primary,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Modified: $formattedDate',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Right: Actions
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (val) {
              if (val == 'edit') {
                onEdit();
              } else if (val == 'delete') {
                onDelete();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 20),
                    SizedBox(width: 8),
                    Text('Edit Template'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 8),
                    Text('Delete Template', style: TextStyle(color: colorScheme.error)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
