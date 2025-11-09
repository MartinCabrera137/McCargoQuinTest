import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../domain/entities/tx.dart';
import '../../../core/formatters/currency_formatter.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});
  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  final _queryCtrl = TextEditingController();
  String? _categoryId;
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = ref.read(currentMonthProvider);
  }

  @override
  Widget build(BuildContext context) {
    final repo  = ref.watch(txRepositoryProvider);
    final cats  = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Transacciones — ${formatMonthYear(_selectedMonth)}'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                  }),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(() {
                    _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                  }),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _queryCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Buscar por concepto',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<String>(
                  value: _categoryId,
                  hint: const Text('Categoría'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Todas')),
                    ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder(
                future: repo.search(
                  month: _selectedMonth,
                  query: _queryCtrl.text,
                  categoryId: _categoryId,
                ),
                builder: (_, snap) {
                  final items = (snap.data ?? const [])..sort((a, b) => b.date.compareTo(a.date));
                  if (items.isEmpty) return const Center(child: Text('Sin transacciones'));
                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final t = items[i];
                      return ListTile(
                        leading: Icon(t.type == TxType.expense ? Icons.remove_circle : Icons.add_circle),
                        title: Text(t.concept),
                        subtitle: Text(
                          '${t.date.toLocal().toString().split(" ").first}'
                              ' • ${t.type == TxType.expense ? (t.categoryId ?? "-") : "Ingreso"}',
                        ),
                        trailing: Text(formatMXN(t.amount)),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
