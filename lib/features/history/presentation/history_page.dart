import 'package:cargoquintest/core/utils/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/month_snapshot.dart';
import 'widgets/past_month_card.dart';

final snapshotsProvider = FutureProvider<List<MonthSnapshot>>((ref) {
  return ref.read(snapshotRepositoryProvider).all();
});

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snaps = ref.watch(snapshotsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Histórico', style: boldTextStyle(color: Colors.white)),
        backgroundColor: AppCustomColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: snaps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (list) {
          if (list.isEmpty) {
            return const Center(child: Text('Aún no hay meses cerrados'));
          }

          return SafeArea(
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final s = list[i];
                return PastMonthCard(
                  snap: s,
                  onTap: null,
                );
              },
            ),
          );
        },
      ),
    );
  }
}
