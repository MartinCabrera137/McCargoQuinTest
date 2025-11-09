enum TxType { income, expense }

class Tx {
  final String id;
  final DateTime date;
  final TxType type;
  final String? categoryId; // en los ingresos sera nulo
  final String concept;
  final double amount;

  Tx({
    required this.id,
    required this.date,
    required this.type,
    required this.categoryId,
    required this.concept,
    required this.amount,
  });
}
