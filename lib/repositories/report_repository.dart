import 'dart:async';
import '../database/report.dart';
import '../database/report_dao.dart';
import '../domain/rules.dart';

abstract class ReportStore {
  Stream<List<Report>> watchAll();
  Future<Report?> find(int id);
  Future<void> save(Draft draft, Report? original);
  Future<void> delete(Report report);
  Future<void> deleteAll();
}

class ReportRepository implements ReportStore {
  final ReportDao _dao;
  Future<void> _tail = Future<void>.value();
  ReportRepository(this._dao);
  @override
  Stream<List<Report>> watchAll() => _dao.watchAll();
  @override
  Future<Report?> find(int id) => _dao.findById(id);
  // Serialize local writes so fetch/validate/update cannot race delete-all.
  Future<void> _write(Future<void> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  @override
  Future<void> save(Draft draft, Report? original) => _write(() async {
    Report? current;
    if (original != null) {
      current = await _dao.findById(original.id!);
      if (current == null) {
        throw const RuleViolation(
          'This report no longer exists. Return to the dashboard.',
        );
      }
      if (current.updatedAt != original.updatedAt) {
        throw const RuleViolation(
          'This report changed elsewhere. Reopen it before editing.',
        );
      }
    }
    final clock = DateTime.now().toUtc().millisecondsSinceEpoch;
    final now = current != null && clock <= current.updatedAt
        ? current.updatedAt + 1
        : clock;
    final report = Rules.prepare(draft, current, now);
    if (current == null) {
      await _dao.insertReport(report);
    } else if (await _dao.updateReport(report) != 1) {
      throw const RuleViolation('This report no longer exists.');
    }
  });
  @override
  Future<void> delete(Report report) => _write(() async {
    if (await _dao.deleteReport(report) != 1) {
      throw const RuleViolation('This report no longer exists.');
    }
  });
  @override
  Future<void> deleteAll() => _write(_dao.deleteAll);
}
