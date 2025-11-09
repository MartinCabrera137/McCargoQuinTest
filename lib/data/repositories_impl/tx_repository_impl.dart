import '../../domain/entities/tx.dart';
import '../../domain/repositories/tx_repository.dart';
import '../datasources/memory/tx_memory_ds.dart';

class TxRepositoryImpl implements TxRepository {
  final TxMemoryDataSource _ds;
  TxRepositoryImpl(this._ds);

  @override Future<void> add(Tx tx) => _ds.add(tx);
  @override Future<List<Tx>> getByMonth(DateTime month) => _ds.byMonth(month);

  @override
  Future<List<Tx>> search({required DateTime month, String? query, String? categoryId})
  => _ds.search(month: month, query: query, categoryId: categoryId);

  @override
  Future<void> clearMonth(DateTime month) => _ds.clearMonth(month);
  @override Future<void> delete(String txId) => _ds.delete(txId);
  @override Future<int> countByCategoryInMonth(DateTime m, String c) => _ds.countByCategoryInMonth(m, c);

}
