import 'package:cargoquintest/features/shared/widgets/Custom_text_fromfield.dart';
import 'package:cargoquintest/features/transactions/presentation/widgets/transactions_usage_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nb_utils/nb_utils.dart';
import '../../../app/providers.dart';
import '../../../core/formatters/date_formatter.dart';
import '../../../core/utils/colors.dart';
import '../../../domain/entities/tx.dart';

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
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(txRepositoryProvider);
    final cats = ref.watch(categoriesProvider);

    String? catName(String? id) {
      if (id == null) return null;
      try {
        return cats.firstWhere((c) => c.id == id).name;
      } catch (_) {
        return null;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Transacciones', style: boldTextStyle(color: Colors.white)),
        backgroundColor: AppCustomColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        actionsIconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            children: [
              // mes y flechas
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      blurRadius: 10,
                      offset: Offset(0, 4),
                      color: Color(0x14000000),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _RoundIconBtn(
                      icon: Icons.chevron_left,
                      onTap: () => setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
                      }),
                    ),
                    Expanded(
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F5F8),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            formatMonthYear(_selectedMonth), // p.ej. "Noviembre 2025"
                            style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: .2),
                          ),
                        ),
                      ),
                    ),
                    _RoundIconBtn(
                      icon: Icons.chevron_right,
                      onTap: () => setState(() {
                        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
                      }),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // buscadfor y drop de la categoria
              Row(
                children: [
                  Expanded(
                    child: CustomTextFormField(
                      hintText: "Buscar movimiento",
                      prefixIcon: Icon(Icons.search),
                      controller: _queryCtrl,
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    width: 135,
                    child: DropdownButtonFormField<String?>(
                      value: _categoryId,
                      decoration: InputDecoration(
                        hintText: 'Categoría',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppCustomColors.primaryBlue),
                        ),
                      ),
                      items: <DropdownMenuItem<String?>>[
                        const DropdownMenuItem(value: null, child: Text('Todas')),
                        ...cats.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // movimeintos
              Expanded(
                child: FutureBuilder<List<Tx>>(
                  future: repo.search(
                    month: _selectedMonth,
                    query: _queryCtrl.text,
                    categoryId: _categoryId,
                  ),
                  builder: (_, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final items = (snap.data ?? const [])..sort((a, b) => b.date.compareTo(a.date));
                    if (items.isEmpty) {
                      return _EmptyState(message: 'Sin transacciones');
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.only(top: 4),
                      itemCount: items.length,
                      itemBuilder: (_, i) {
                        final t = items[i];
                        final name = t.type == TxType.expense ? catName(t.categoryId) : null;
                        return TransactionTile(
                          tx: t,
                          categoryName: name,
                          onDelete: null,
                          onTap: null,
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _RoundIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE9EDF2),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(icon, size: 20, color: Color(0xFF374151)),
        ),
      ),
    );
  }
}

// si no hay datos motrar algo
class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 56, height: 56,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFE9EDF2)),
          child: const Icon(Icons.receipt_long, color: Color(0xFF6B7280)),
        ),
        const SizedBox(height: 10),
        Text(message, style: secondaryTextStyle()),
      ]),
    );
  }
}
