import 'package:exam_prep_pro/core/services/content_cache.dart';
import 'package:exam_prep_pro/core/services/database_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfiNoIsolate;
  });

  test('reuses cached content until invalidated', () async {
    final db = DatabaseHelper(overridePath: inMemoryDatabasePath);
    final cache = ContentCache(db);
    var fetchCount = 0;

    Future<List<Map<String, dynamic>>> fetch() async {
      fetchCount++;
      return [
        {'id': 'ch1', 'title': 'Electrical'},
      ];
    }

    expect(await cache.getOrFetch('chapters', fetch), hasLength(1));
    expect(await cache.getOrFetch('chapters', fetch), hasLength(1));
    expect(fetchCount, 1);

    await cache.invalidate('chapters');
    await cache.getOrFetch('chapters', fetch);
    expect(fetchCount, 2);

    await db.close();
  });
}
