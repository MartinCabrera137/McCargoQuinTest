import '../entities/category.dart';

abstract class MonthCategoryRepository {
  List<Category> getByMonth(DateTime month);
  void upsert(DateTime month, Category c);
  void upsertMany(DateTime month, List<Category> cs);
  void rename(DateTime month, String categoryId, String newName);
  bool delete(DateTime month, String categoryId);
}
