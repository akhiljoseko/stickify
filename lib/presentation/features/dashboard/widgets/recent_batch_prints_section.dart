import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/presentation/features/dashboard/cubits/recent_batch_summaries_cubit.dart';
import 'package:stickify/presentation/features/dashboard/widgets/batch_print_summary_card.dart';

/// Section widget rendered on Dashboard displaying a horizontal list of recent batch print job summary cards.
class RecentBatchPrintsSection extends StatelessWidget {
  /// Creates a [RecentBatchPrintsSection].
  const RecentBatchPrintsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    RecentBatchSummariesCubit? cubit;
    try {
      cubit = context.read<RecentBatchSummariesCubit>();
    } catch (_) {}

    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recent Batch Prints',
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Batch print history from the last 7 days.',
                    style: textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        BlocBuilder<RecentBatchSummariesCubit, RecentBatchSummariesState>(
          builder: (context, state) {
            if (state is RecentBatchSummariesLoading || state is RecentBatchSummariesInitial) {
              return SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: 3,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) => Container(
                    width: 290,
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }

            if (state is RecentBatchSummariesLoaded) {
              if (state.summaries.isEmpty) {
                return Card(
                  color: colorScheme.surfaceContainerLowest,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          color: colorScheme.onSurfaceVariant,
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'No batch print jobs performed in the last 7 days.',
                            style: textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 160,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: state.summaries.length,
                  separatorBuilder: (context, index) => const SizedBox(width: 16),
                  itemBuilder: (context, index) {
                    return BatchPrintSummaryCard(
                      summary: state.summaries[index],
                    );
                  },
                ),
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }
}
