// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// **************************************************************************
// FloorGenerator
// **************************************************************************

abstract class $AppDatabaseBuilderContract {
  /// Adds migrations to the builder.
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations);

  /// Adds a database [Callback] to the builder.
  $AppDatabaseBuilderContract addCallback(Callback callback);

  /// Creates the database and initializes it.
  Future<AppDatabase> build();
}

// ignore: avoid_classes_with_only_static_members
class $FloorAppDatabase {
  /// Creates a database builder for a persistent database.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract databaseBuilder(String name) =>
      _$AppDatabaseBuilder(name);

  /// Creates a database builder for an in memory database.
  /// Information stored in an in memory database disappears when the process is killed.
  /// Once a database is built, you should keep a reference to it and re-use it.
  static $AppDatabaseBuilderContract inMemoryDatabaseBuilder() =>
      _$AppDatabaseBuilder(null);
}

class _$AppDatabaseBuilder implements $AppDatabaseBuilderContract {
  _$AppDatabaseBuilder(this.name);

  final String? name;

  final List<Migration> _migrations = [];

  Callback? _callback;

  @override
  $AppDatabaseBuilderContract addMigrations(List<Migration> migrations) {
    _migrations.addAll(migrations);
    return this;
  }

  @override
  $AppDatabaseBuilderContract addCallback(Callback callback) {
    _callback = callback;
    return this;
  }

  @override
  Future<AppDatabase> build() async {
    final path = name != null
        ? await sqfliteDatabaseFactory.getDatabasePath(name!)
        : ':memory:';
    final database = _$AppDatabase();
    database.database = await database.open(path, _migrations, _callback);
    return database;
  }
}

class _$AppDatabase extends AppDatabase {
  _$AppDatabase([StreamController<String>? listener]) {
    changeListener = listener ?? StreamController<String>.broadcast();
  }

  ReportDao? _reportDaoInstance;

  Future<sqflite.Database> open(
    String path,
    List<Migration> migrations, [
    Callback? callback,
  ]) async {
    final databaseOptions = sqflite.OpenDatabaseOptions(
      version: 1,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
        await callback?.onConfigure?.call(database);
      },
      onOpen: (database) async {
        await callback?.onOpen?.call(database);
      },
      onUpgrade: (database, startVersion, endVersion) async {
        await MigrationAdapter.runMigrations(
          database,
          startVersion,
          endVersion,
          migrations,
        );

        await callback?.onUpgrade?.call(database, startVersion, endVersion);
      },
      onCreate: (database, version) async {
        await database.execute(
          'CREATE TABLE IF NOT EXISTS `reports` (`id` INTEGER PRIMARY KEY AUTOINCREMENT, `train` TEXT NOT NULL, `carriage` INTEGER NOT NULL, `component` TEXT NOT NULL, `description` TEXT NOT NULL, `priority` TEXT NOT NULL, `status` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `updatedAt` INTEGER NOT NULL, `latitude` REAL, `longitude` REAL, `locationCapturedAt` INTEGER, `resolutionNotes` TEXT, `resolvedAt` INTEGER)',
        );

        await callback?.onCreate?.call(database, version);
      },
    );
    return sqfliteDatabaseFactory.openDatabase(path, options: databaseOptions);
  }

  @override
  ReportDao get reportDao {
    return _reportDaoInstance ??= _$ReportDao(database, changeListener);
  }
}

class _$ReportDao extends ReportDao {
  _$ReportDao(this.database, this.changeListener)
    : _queryAdapter = QueryAdapter(database, changeListener),
      _reportInsertionAdapter = InsertionAdapter(
        database,
        'reports',
        (Report item) => <String, Object?>{
          'id': item.id,
          'train': item.train,
          'carriage': item.carriage,
          'component': item.component,
          'description': item.description,
          'priority': item.priority,
          'status': item.status,
          'createdAt': item.createdAt,
          'updatedAt': item.updatedAt,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'locationCapturedAt': item.locationCapturedAt,
          'resolutionNotes': item.resolutionNotes,
          'resolvedAt': item.resolvedAt,
        },
        changeListener,
      ),
      _reportUpdateAdapter = UpdateAdapter(
        database,
        'reports',
        ['id'],
        (Report item) => <String, Object?>{
          'id': item.id,
          'train': item.train,
          'carriage': item.carriage,
          'component': item.component,
          'description': item.description,
          'priority': item.priority,
          'status': item.status,
          'createdAt': item.createdAt,
          'updatedAt': item.updatedAt,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'locationCapturedAt': item.locationCapturedAt,
          'resolutionNotes': item.resolutionNotes,
          'resolvedAt': item.resolvedAt,
        },
        changeListener,
      ),
      _reportDeletionAdapter = DeletionAdapter(
        database,
        'reports',
        ['id'],
        (Report item) => <String, Object?>{
          'id': item.id,
          'train': item.train,
          'carriage': item.carriage,
          'component': item.component,
          'description': item.description,
          'priority': item.priority,
          'status': item.status,
          'createdAt': item.createdAt,
          'updatedAt': item.updatedAt,
          'latitude': item.latitude,
          'longitude': item.longitude,
          'locationCapturedAt': item.locationCapturedAt,
          'resolutionNotes': item.resolutionNotes,
          'resolvedAt': item.resolvedAt,
        },
        changeListener,
      );

  final sqflite.DatabaseExecutor database;

  final StreamController<String> changeListener;

  final QueryAdapter _queryAdapter;

  final InsertionAdapter<Report> _reportInsertionAdapter;

  final UpdateAdapter<Report> _reportUpdateAdapter;

  final DeletionAdapter<Report> _reportDeletionAdapter;

  @override
  Stream<List<Report>> watchAll() {
    return _queryAdapter.queryListStream(
      'SELECT * FROM reports ORDER BY updatedAt DESC, id DESC',
      mapper: (Map<String, Object?> row) => Report(
        id: row['id'] as int?,
        train: row['train'] as String,
        carriage: row['carriage'] as int,
        component: row['component'] as String,
        description: row['description'] as String,
        priority: row['priority'] as String,
        status: row['status'] as String,
        createdAt: row['createdAt'] as int,
        updatedAt: row['updatedAt'] as int,
        latitude: row['latitude'] as double?,
        longitude: row['longitude'] as double?,
        locationCapturedAt: row['locationCapturedAt'] as int?,
        resolutionNotes: row['resolutionNotes'] as String?,
        resolvedAt: row['resolvedAt'] as int?,
      ),
      queryableName: 'reports',
      isView: false,
    );
  }

  @override
  Future<Report?> findById(int id) async {
    return _queryAdapter.query(
      'SELECT * FROM reports WHERE id = ?1',
      mapper: (Map<String, Object?> row) => Report(
        id: row['id'] as int?,
        train: row['train'] as String,
        carriage: row['carriage'] as int,
        component: row['component'] as String,
        description: row['description'] as String,
        priority: row['priority'] as String,
        status: row['status'] as String,
        createdAt: row['createdAt'] as int,
        updatedAt: row['updatedAt'] as int,
        latitude: row['latitude'] as double?,
        longitude: row['longitude'] as double?,
        locationCapturedAt: row['locationCapturedAt'] as int?,
        resolutionNotes: row['resolutionNotes'] as String?,
        resolvedAt: row['resolvedAt'] as int?,
      ),
      arguments: [id],
    );
  }

  @override
  Future<void> deleteAll() async {
    await _queryAdapter.queryNoReturn('DELETE FROM reports');
  }

  @override
  Future<int> insertReport(Report report) {
    return _reportInsertionAdapter.insertAndReturnId(
      report,
      OnConflictStrategy.abort,
    );
  }

  @override
  Future<int> updateReport(Report report) {
    return _reportUpdateAdapter.updateAndReturnChangedRows(
      report,
      OnConflictStrategy.abort,
    );
  }

  @override
  Future<int> deleteReport(Report report) {
    return _reportDeletionAdapter.deleteAndReturnChangedRows(report);
  }
}
