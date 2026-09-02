import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:stickify/auth/auth.dart';
import 'package:stickify/core/services/product_brochure_generator.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/settings/cubit/settings_cubit.dart';
import 'package:stickify/presentation/settings/cubit/settings_state.dart';

/// Settings screen — designated place for app preferences and Logout.
class SettingsScreen extends StatelessWidget {
  /// Creates a [SettingsScreen] instance.
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => SettingsCubit(
        settingsRepository: context.read<SettingsRepository>(),
        productRepository: context.read<ProductRepository>(),
        brochureGenerator: context.read<ProductBrochureGenerator>(),
      )..loadSettings(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return BlocListener<SettingsCubit, SettingsState>(
      listenWhen: (prev, curr) =>
          prev.brochureExportStatus != curr.brochureExportStatus,
      listener: (context, state) {
        switch (state.brochureExportStatus) {
          case BrochureExportStatus.success:
            final path = state.brochureSavedPath;
            final message = path != null && path.isNotEmpty
                ? 'Brochure saved to: $path'
                : 'Brochure shared successfully!';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: colorScheme.primary,
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 6),
              ),
            );
          case BrochureExportStatus.failure:
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.brochureExportError ?? 'Export failed. Please try again.',
                ),
                backgroundColor: colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          case BrochureExportStatus.idle:
          case BrochureExportStatus.loading:
            break;
        }
      },
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Settings', style: textTheme.displayLarge),
              const SizedBox(height: 8),
              Text(
                'Manage your account and application preferences.',
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),

              // ── Print Pipeline Configuration ──────────────────────────────
              Text(
                'Print Pipeline Configuration',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<SettingsCubit, SettingsState>(
                builder: (context, state) {
                  final settings = state.settings;
                  final cubit = context.read<SettingsCubit>();

                  return Card(
                    child: Column(
                      children: [
                        SwitchListTile(
                          secondary: const Icon(Icons.auto_awesome),
                          title: const Text('Default Template Auto-Skip'),
                          subtitle: const Text(
                            'Automatically skip template selection in single product print workflow when a default template is assigned to the variant',
                          ),
                          value: settings.enableDefaultTemplateUsage,
                          onChanged: (val) =>
                              cubit.setEnableDefaultTemplateUsage(value: val),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant),
                        SwitchListTile(
                          secondary: const Icon(Icons.grid_on_outlined),
                          title: const Text('Resume Partial Sheet Memory'),
                          subtitle: const Text(
                            'Automatically restore unused sticker slot positions from the last printed partial sheet when initializing print setup',
                          ),
                          value: settings.enableResumePartialSheet,
                          onChanged: (val) =>
                              cubit.setEnableResumePartialSheet(value: val),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant),
                        SwitchListTile(
                          secondary: const Icon(Icons.vertical_align_bottom),
                          title: const Text('Print Labels from Bottom'),
                          subtitle: const Text(
                            'Align sticker label placement starting from the bottom of physical paper sheets',
                          ),
                          value: settings.printFromBottom,
                          onChanged: (val) =>
                              cubit.setPrintFromBottom(value: val),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant),
                        SwitchListTile(
                          secondary: const Icon(Icons.layers_outlined),
                          title: const Text('Group Product Variants in Batch Print'),
                          subtitle: const Text(
                            'Group identical product variants together in order of first appearance so they print continuously on sticker sheets',
                          ),
                          value: settings.groupBatchVariants,
                          onChanged: (val) =>
                              cubit.setGroupBatchVariants(value: val),
                        ),
                        Divider(height: 1, color: colorScheme.outlineVariant),
                        SwitchListTile(
                          secondary: const Icon(Icons.description_outlined),
                          title: const Text('Spool Batch Sheets Separately'),
                          subtitle: const Text(
                            'Send batch print jobs as separate 1-page print spool documents to the printer queue to isolate paper jams and print errors per sheet',
                          ),
                          value: settings.enablePerSheetSpooling,
                          onChanged: (val) =>
                              cubit.setEnablePerSheetSpooling(value: val),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // ── Data & Export ─────────────────────────────────────────────
              Text(
                'Data & Export',
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              BlocBuilder<SettingsCubit, SettingsState>(
                buildWhen: (prev, curr) =>
                    prev.brochureExportStatus != curr.brochureExportStatus,
                builder: (context, state) {
                  final isLoading = state.brochureExportStatus ==
                      BrochureExportStatus.loading;
                  final cubit = context.read<SettingsCubit>();

                  return Card(
                    child: ListTile(
                      leading: isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator.adaptive(
                                strokeWidth: 2.5,
                              ),
                            )
                          : Icon(
                              Icons.picture_as_pdf_outlined,
                              color: colorScheme.primary,
                            ),
                      title: const Text('Export Product Brochure'),
                      subtitle: const Text(
                        'Generate a colour product catalogue PDF with all products '
                        'and variant pricing, then save it to your Downloads folder.',
                      ),
                      trailing: isLoading
                          ? null
                          : Icon(
                              Icons.chevron_right,
                              color: colorScheme.onSurfaceVariant,
                            ),
                      onTap: isLoading ? null : cubit.exportProductBrochure,
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // ── Logout Section ─────────────────────────────────────────────
              Card(
                child: ListTile(
                  leading: Icon(Icons.logout, color: colorScheme.error),
                  title: Text(
                    'Sign Out',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'You will be redirected to the login screen',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  onTap: () => context.read<AuthCubit>().logout(),
                ),
              ),
              const SizedBox(height: 32),
              Center(
                child: FutureBuilder<PackageInfo>(
                  future: PackageInfo.fromPlatform(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final info = snapshot.data!;
                      return Text(
                        'Version ${info.version}',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
