import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../domain/entities/tx.dart';

final monthTxsProvider = FutureProvider<List<Tx>>((ref) async {
  final month = ref.watch(currentMonthProvider);
  final repo  = ref.read(txRepositoryProvider);
  final txs = await repo.getByMonth(month);
  txs.sort((a, b) => b.date.compareTo(a.date));
  return txs;
});
