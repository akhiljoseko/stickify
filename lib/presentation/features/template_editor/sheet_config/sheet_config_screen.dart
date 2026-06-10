import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_cubit.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/bloc/sheet_config_state.dart';
import 'package:stickify/presentation/features/template_editor/sheet_config/widgets/sheet_preview_grid.dart';
import 'package:stickify/presentation/features/template_editor/widgets/wizard_step_indicator.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class SheetConfigScreen extends StatelessWidget {
  const SheetConfigScreen({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SheetConfigCubit(
        context.read<TemplateRepository>(),
        templateId,
      )..load(),
      child: const _SheetConfigView(),
    );
  }
}

class _SheetConfigView extends StatefulWidget {
  const _SheetConfigView();

  @override
  State<_SheetConfigView> createState() => _SheetConfigViewState();
}

class _SheetConfigViewState extends State<_SheetConfigView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<SheetConfigCubit, SheetConfigState>(
      listener: (context, state) {
        if (state is SheetConfigSaved) {
          StickerSetupRoute(templateId: state.templateId).go(context);
        }
        if (state is SheetConfigError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is SheetConfigLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is SheetConfigEditing) {
          final config = state.config;

          final formPane = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Page Setup', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                
                // Page Size Dropdown
                DropdownButtonFormField<String>(
                  initialValue: config.pageSize,
                  decoration: const InputDecoration(
                    labelText: 'Page Size',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'A4', child: Text('A4 (210 x 297 mm)')),
                    DropdownMenuItem(value: 'Letter', child: Text('Letter (215.9 x 279.4 mm)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      context.read<SheetConfigCubit>().updateConfig(
                            config.copyWith(pageSize: val),
                          );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Columns & Rows
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: config.columns.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Columns',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final count = int.tryParse(val) ?? 1;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(columns: count),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: config.rows.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Rows',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (val) {
                          final count = int.tryParse(val) ?? 1;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(rows: count),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Page Margins (mm)', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                
                // Margin inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: config.marginTop.toString(),
                        decoration: const InputDecoration(labelText: 'Top'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(marginTop: num),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: config.marginBottom.toString(),
                        decoration: const InputDecoration(labelText: 'Bottom'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(marginBottom: num),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: config.marginLeft.toString(),
                        decoration: const InputDecoration(labelText: 'Left'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(marginLeft: num),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: config.marginRight.toString(),
                        decoration: const InputDecoration(labelText: 'Right'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(marginRight: num),
                              );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Text('Sticker Spacing / Gaps (mm)', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                
                // Spacing gaps
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: config.columnGap.toString(),
                        decoration: const InputDecoration(labelText: 'Horizontal Gap'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(columnGap: num),
                              );
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: config.rowGap.toString(),
                        decoration: const InputDecoration(labelText: 'Vertical Gap'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<SheetConfigCubit>().updateConfig(
                                config.copyWith(rowGap: num),
                              );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );

          final previewPane = Container(
            color: colorScheme.surfaceContainerLow,
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Text('Live Sheet Matrix Preview', style: textTheme.titleSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: SheetPreviewGrid(config: config),
                ),
              ],
            ),
          );

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Sheet Layout Configuration'),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: WizardStepIndicator(currentStep: 1),
              ),
            ),
            body: Column(
              children: [
                Expanded(
                  child: AdaptiveLayoutSwitcher(
                    mobile: AdaptiveScrollWrapper(
                      builder: (context, controller) => SingleChildScrollView(
                        controller: controller,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            formPane,
                            const SizedBox(height: 32),
                            SizedBox(height: 350, child: previewPane),
                          ],
                        ),
                      ),
                    ),
                    desktop: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 4,
                          child: AdaptiveScrollWrapper(
                            builder: (context, controller) => SingleChildScrollView(
                              controller: controller,
                              padding: const EdgeInsets.all(32),
                              child: formPane,
                            ),
                          ),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          flex: 6,
                          child: previewPane,
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    border: Border(
                      top: BorderSide(color: colorScheme.outlineVariant),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton(
                        onPressed: () => const TemplateManagementRoute().go(context),
                        child: const Text('Back to List'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<SheetConfigCubit>().saveAndContinue(),
                        child: const Text('Next: Sticker Setup'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
