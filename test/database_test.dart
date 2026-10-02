import 'package:flutter_test/flutter_test.dart';
import 'package:railcheck/database/app_database.dart';
import 'package:railcheck/domain/rules.dart';
import 'package:railcheck/repositories/report_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'Floor CRUD, stream notifications, deterministic order and delete-all',
    () async {
      final db = await $FloorAppDatabase.inMemoryDatabaseBuilder().build();
      final dao = db.reportDao;
      final events = <int>[];
      final sub = dao.watchAll().listen((list) => events.add(list.length));
      final r = Rules.prepare(
        Draft(train: 'Train 205', description: 'Door does not close.'),
        null,
        100,
      );
      final first = await dao.insertReport(r);
      final second = await dao.insertReport(r);
      expect(second, greaterThan(first));
      final all = await dao.watchAll().first;
      expect(all.map((r) => r.id).toList(), [second, first]);
      final stored = (await dao.findById(first))!;
      final repository = ReportRepository(dao);
      await repository.save(
        Draft.fromReport(stored)..status = 'in_progress',
        stored,
      );
      final updated = (await dao.findById(first))!;
      expect(updated.status, 'in_progress');
      expect(updated.createdAt, 100);
      await expectLater(
        repository.save(Draft.fromReport(stored), stored),
        throwsA(isA<RuleViolation>()),
      );
      await repository.delete(updated);
      expect(await dao.findById(first), isNull);
      // Listen before mutation: checks DELETE query invalidates Floor streams.
      final empty = dao
          .watchAll()
          .firstWhere((reports) => reports.isEmpty)
          .timeout(const Duration(seconds: 5));
      await repository.deleteAll();
      expect(await empty, isEmpty);
      expect(await dao.findById(second), isNull);
      await sub.cancel();
      await db.close();
    },
  );
}
