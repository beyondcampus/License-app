import '../../../core/services/content_source.dart';
import '../domain/formula.dart';

abstract class FormulaRepository {
  Future<List<Formula>> getAll();
  Future<List<Formula>> getByChapter(String chapterId);
  Future<List<Formula>> getByIds(List<String> ids);
  Future<List<Formula>> search(String query);
}

class FormulaRepositoryImpl implements FormulaRepository {
  FormulaRepositoryImpl(this._source);

  final ContentSource _source;

  @override
  Future<List<Formula>> getAll() => _source.formulas();

  @override
  Future<List<Formula>> getByChapter(String chapterId) =>
      _source.formulas(chapterId: chapterId);

  @override
  Future<List<Formula>> getByIds(List<String> ids) async {
    final wanted = ids.toSet();
    return (await _source.formulas())
        .where((f) => wanted.contains(f.id))
        .toList();
  }

  @override
  Future<List<Formula>> search(String query) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return getAll();
    return (await _source.formulas())
        .where((f) =>
            f.title.toLowerCase().contains(q) ||
            f.plainText.toLowerCase().contains(q) ||
            f.description.toLowerCase().contains(q))
        .toList();
  }
}
