import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:floor/floor.dart' hide sqfliteDatabaseFactory;
import 'package:floor/floor.dart' as floor show sqfliteDatabaseFactory;
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'report.dart';
import 'report_dao.dart';
part 'app_database.g.dart';

// Floor generated code uses this factory for both paths and database operations.
// Avoid worker messaging on Web; native platforms keep Floor's usual factory.
final sqflite.DatabaseFactory sqfliteDatabaseFactory = kIsWeb
    ? databaseFactoryFfiWebNoWebWorker
    : floor.sqfliteDatabaseFactory;

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
      if (kIsWeb) {
        // Web SQLite uses a virtual filesystem rooted at '/'. Set it explicitly
        // before Floor asks for the path: worker-based discovery can return null.
        await sqfliteDatabaseFactory.setDatabasesPath('/');
      }
      // For schema changes: increment version and add Migration objects here.
      // Never remove a user's database to recover from an initialization error.
      return await $FloorAppDatabase.databaseBuilder('railcheck.db').build();
    } catch (_) {
      _opening = null;
      rethrow;
    }
  }
}
