import 'dart:async';
import 'package:floor/floor.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'report.dart';
import 'report_dao.dart';
part 'app_database.g.dart';

@Database(version: 1, entities: [Report])
abstract class AppDatabase extends FloorDatabase {
  ReportDao get reportDao;
}

class DatabaseService {
  DatabaseService._();
  static final DatabaseService instance = DatabaseService._();
  Future<AppDatabase>? _opening;
  Future<AppDatabase> get database => _opening ??= _open();
  Future<AppDatabase> _open() async {
    try {
      // For schema changes: increment version and add Migration objects here.
      // Never remove a user's database to recover from an initialization error.
      return await $FloorAppDatabase.databaseBuilder('railcheck.db').build();
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }
}
