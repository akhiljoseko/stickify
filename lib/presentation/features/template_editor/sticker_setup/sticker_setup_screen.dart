import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_cubit.dart';
import 'package:stickify/presentation/features/template_editor/sticker_setup/bloc/sticker_setup_state.dart';
import 'package:stickify/presentation/features/template_editor/widgets/wizard_step_indicator.dart';
import 'package:stickify/presentation/widgets/adaptive_layout_switcher.dart';
import 'package:stickify/presentation/widgets/adaptive_scroll_wrapper.dart';

class StickerSetupScreen extends StatelessWidget {
  const StickerSetupScreen({required this.templateId, super.key});

  final String templateId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StickerSetupCubit(
        context.read<TemplateRepository>(),
        templateId,
      )..load(),
      child: const _StickerSetupView(),
    );
  }
}

class _StickerSetupView extends StatefulWidget {
  const _StickerSetupView();

  @override
  State<_StickerSetupView> createState() => _StickerSetupViewState();
}

class _StickerSetupViewState extends State<_StickerSetupView> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocConsumer<StickerSetupCubit, StickerSetupState>(
      listener: (context, state) {
        if (state is StickerSetupSaved) {
          LabelEditorRoute(templateId: state.templateId).go(context);
        }
        if (state is StickerSetupError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: colorScheme.error,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is StickerSetupLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is StickerSetupEditing) {
          final formPane = Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sticker Dimensions', style: textTheme.titleMedium),
                const SizedBox(height: 16),
                
                // Width & Height
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: state.widthMm.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Width (mm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 10.0;
                          context.read<StickerSetupCubit>().updateFields(widthMm: num);
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        initialValue: state.heightMm.toString(),
                        decoration: const InputDecoration(
                          labelText: 'Height (mm)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 10.0;
                          context.read<StickerSetupCubit>().updateFields(heightMm: num);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Corner Radius
                TextFormField(
                  initialValue: state.cornerRadiusMm.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Corner Radius (mm)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) {
                    final num = double.tryParse(val) ?? 0.0;
                    context.read<StickerSetupCubit>().updateFields(cornerRadiusMm: num);
                  },
                ),
                const SizedBox(height: 24),

                Text('Printable Area Padding / Margins (mm)', style: textTheme.titleSmall),
                const SizedBox(height: 12),
                
                // Padding inputs
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: state.paddingTop.toString(),
                        decoration: const InputDecoration(labelText: 'Top'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<StickerSetupCubit>().updateFields(paddingTop: num);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: state.paddingBottom.toString(),
                        decoration: const InputDecoration(labelText: 'Bottom'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<StickerSetupCubit>().updateFields(paddingBottom: num);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: state.paddingLeft.toString(),
                        decoration: const InputDecoration(labelText: 'Left'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<StickerSetupCubit>().updateFields(paddingLeft: num);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        initialValue: state.paddingRight.toString(),
                        decoration: const InputDecoration(labelText: 'Right'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        onChanged: (val) {
                          final num = double.tryParse(val) ?? 0.0;
                          context.read<StickerSetupCubit>().updateFields(paddingRight: num);
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
                Text('Live Sticker Layout Preview', style: textTheme.titleSmall),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      // Draw the sticker scaled dynamically
                      final aspect = state.widthMm / state.heightMm;
                      final maxW = constraints.maxWidth - 40;
                      final maxH = constraints.maxHeight - 40;

                      var drawW = maxW;
                      var drawH = maxW / aspect;

                      if (drawH > maxH) {
                        drawH = maxH;
                        drawW = maxH * aspect;
                      }

                      // Convert mm radius to pixels
                      final scale = drawW / state.widthMm;
                      final radiusPx = state.cornerRadiusMm * scale;
                      
                      // Calculate paddings in pixels
                      final pTop = state.paddingTop * scale;
                      final pBottom = state.paddingBottom * scale;
                      final pLeft = state.paddingLeft * scale;
                      final pRight = state.paddingRight * scale;

                      return Center(
                        child: Container(
                          width: drawW,
                          height: drawH,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(radiusPx),
                            border: Border.all(color: colorScheme.outlineVariant, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.08),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              // Safe printable area boundary representation
                              if (drawW - pLeft - pRight > 0 && drawH - pTop - pBottom > 0)
                                Positioned(
                                  left: pLeft,
                                  top: pTop,
                                  width: drawW - pLeft - pRight,
                                  height: drawH - pTop - pBottom,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: Colors.red.shade300,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Printable Safe Area',
                                        style: TextStyle(
                                          color: Colors.red.shade300,
                                          fontSize: 10,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );

          return Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              title: const Text('Sticker Layout Configuration'),
              bottom: const PreferredSize(
                preferredSize: Size.fromHeight(60),
                child: WizardStepIndicator(currentStep: 2),
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
                        onPressed: () => SheetConfigRoute(
                          templateId: context.read<StickerSetupCubit>().templateId,
                        ).go(context),
                        child: const Text('Back'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<StickerSetupCubit>().saveAndContinue(),
                        child: const Text('Next: Label Designer'),
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
