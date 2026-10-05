import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

/// Web: back sqflite with the WASM/IndexedDB implementation so user data
/// (results, bookmarks, reviews, progress) persists in the browser too.
void configureDatabaseFactory() {
  databaseFactory = databaseFactoryFfiWeb;
}
