import '../../domain/repositories/month_category_repository.dart';
import '../../domain/entities/category.dart';
import '../datasources/memory/month_category_ds.dart';

class MonthCategoryRepositoryImpl implements MonthCategoryRepository {
  final MonthCategoryMemoryDataSource _ds;
  MonthCategoryRepositoryImpl(this._ds);

  @override List<Category> getByMonth(DateTime month) => _ds.getByMonth(month);
  @override void upsert(DateTime month, Category c) => _ds.upsert(month, c);
  @override void upsertMany(DateTime month, List<Category> cs) => _ds.upsertMany(month, cs);
  @override void rename(DateTime month, String id, String name) => _ds.rename(month, id, name);
  @override bool delete(DateTime month, String id) => _ds.delete(month, id);
}
