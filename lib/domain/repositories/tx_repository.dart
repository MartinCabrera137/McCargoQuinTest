import '../entities/tx.dart';

abstract class TxRepository {
  Future<void> add(Tx tx);
  Future<List<Tx>> getByMonth(DateTime month);

  // buscador para las categorias
  Future<List<Tx>> search({
    required DateTime month,
    String? query,
    String? categoryId,  //filtro por categoria
  });

  // para cierre de mes
  Future<void> clearMonth(DateTime month);
  //para dar de baja conceptos
  Future<void> delete(String txId);
  //contador
  Future<int> countByCategoryInMonth(DateTime month, String categoryId);
}
