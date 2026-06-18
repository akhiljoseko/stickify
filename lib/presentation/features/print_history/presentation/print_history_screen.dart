import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:stickify/app/routing/router.dart';
import 'package:stickify/domain/domain.dart';
import 'package:stickify/presentation/features/dashboard/widgets/recent_print_row.dart';
import 'package:stickify/presentation/features/print_history/cubits/print_history_cubit.dart';
import 'package:stickify/presentation/features/print_history/cubits/print_history_state.dart';

class PrintHistoryScreen extends StatefulWidget {
  const PrintHistoryScreen({super.key});

  @override
  State<PrintHistoryScreen> createState() => _PrintHistoryScreenState();
}

class _PrintHistoryScreenState extends State<PrintHistoryScreen> {
  final _scrollController = ScrollController();
  late final PrintHistoryCubit _historyCubit;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _historyCubit = PrintHistoryCubit(
      printJobRepository: context.read<PrintJobRepository>(),
    );
    _historyCubit.loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _historyCubit.close();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      _historyCubit.loadNextPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Print History'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: BlocBuilder<PrintHistoryCubit, PrintHistoryState>(
        bloc: _historyCubit,
        builder: (context, state) => switch (state) {
          PrintHistoryInitial() || PrintHistoryLoading() => const Center(
            child: CircularProgressIndicator(),
          ),
          PrintHistoryError(:final message) => Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, color: colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text(message, style: textTheme.bodyMedium),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      context.read<PrintHistoryCubit>().loadFirstPage(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
          PrintHistoryLoaded(:final jobs) =>
            jobs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.print_outlined,
                          color: colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No print jobs yet',
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : _PrintHistoryTable(jobs: jobs, state: state),
          PrintHistoryLoadingMore(:final jobs) => _PrintHistoryTable(
            jobs: jobs,
            state: state,
            isLoadingMore: true,
          ),
        },
      ),
    );
  }
}

class _PrintHistoryTable extends StatelessWidget {
  const _PrintHistoryTable({
    required this.jobs,
    required this.state,
    this.isLoadingMore = false,
  });

  final List<PrintJob> jobs;
  final PrintHistoryState state;
  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView(
        controller: ScrollController(),
        children: [
          ...jobs.map((job) => RecentPrintRow(
            job: job,
            onRepeatPrint: () => PrintSetupRoute(
              productId: job.productId,
              variantSku: job.variantSku,
              templateId: job.templateId,
              quantity: job.labelCount,
            ).go(context),
          )),
          if (isLoadingMore)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
        ],
      ),
    );
  }
}
