import 'package:flutter_test/flutter_test.dart';
import 'package:railcheck/domain/rules.dart';
import 'package:railcheck/database/report.dart';

Draft valid() =>
    Draft(train: '  RC-A12  ', description: '  Door cannot close safely.  ');
Report previous(String status) {
  final d = valid();
  final open = Rules.prepare(d, null, 100);
  if (status == 'open') return open;
  d.status = 'in_progress';
  final progress = Rules.prepare(d, open, 200);
  if (status == 'in_progress') return progress;
  d.status = 'resolved';
  d.notes = 'Door motor was replaced.';
  return Rules.prepare(d, progress, 300);
}

void main() {
  test('trims identifiers and description and allows letters', () {
    final r = Rules.prepare(valid(), null, 100);
    expect(r.train, 'RC-A12');
    expect(r.description, 'Door cannot close safely.');
    expect(r.status, 'open');
    expect(r.createdAt, 100);
  });
  test('validates whitespace and exact length boundaries', () {
    expect(Rules.trainError('  '), isNotNull);
    expect(Rules.trainError('a' * 30), isNull);
    expect(Rules.trainError('a' * 31), isNotNull);
    expect(Rules.descriptionError(' ' * 50), isNotNull);
    expect(Rules.descriptionError('x' * 9), isNotNull);
    expect(Rules.descriptionError('  ${'x' * 10}  '), isNull);
    expect(Rules.descriptionError('x' * 1000), isNull);
    expect(Rules.descriptionError('x' * 1001), isNotNull);
  });
  test('checks every allowed and forbidden transition', () {
    const allowed = {
      'open:open',
      'open:in_progress',
      'in_progress:in_progress',
      'in_progress:resolved',
      'resolved:resolved',
      'resolved:open',
    };
    for (final old in ['open', 'in_progress', 'resolved']) {
      for (final next in ['open', 'in_progress', 'resolved']) {
        final d = valid()
          ..status = next
          ..notes = 'Replaced faulty door motor.';
        if (allowed.contains('$old:$next')) {
          expect(() => Rules.prepare(d, previous(old), 400), returnsNormally);
        } else {
          expect(
            () => Rules.prepare(d, previous(old), 400),
            throwsA(isA<RuleViolation>()),
          );
        }
      }
    }
    expect(
      () => Rules.prepare(valid()..status = 'resolved', null, 1),
      throwsA(isA<RuleViolation>()),
    );
  });
  test(
    'resolution notes required and timestamp is preserved on later edits',
    () {
      for (final notes in ['', '    ', 'too short', 'x' * 1001]) {
        final d = valid()
          ..status = 'resolved'
          ..notes = notes;
        expect(
          () => Rules.prepare(d, previous('in_progress'), 400),
          throwsA(isA<RuleViolation>()),
        );
      }
      final r = previous('resolved');
      final updated = Rules.prepare(
        Draft.fromReport(r)..description = 'New detailed description.',
        r,
        500,
      );
      expect(updated.createdAt, 100);
      expect(updated.updatedAt, 500);
      expect(updated.resolvedAt, 300);
    },
  );
  test('reopening clears current resolution metadata', () {
    final old = previous('resolved');
    final r = Rules.prepare(Draft.fromReport(old)..status = 'open', old, 400);
    expect(r.resolvedAt, isNull);
    expect(r.resolutionNotes, isNull);
    expect(r.createdAt, old.createdAt);
  });
  test('location is all-null or all-present, finite and in range', () {
    expect(() => Rules.validateLocation(null, null, null), returnsNormally);
    expect(
      () => Rules.validateLocation(0, 0, 0),
      returnsNormally,
    ); // Real 0,0 is valid, never a fallback.
    expect(() => Rules.validateLocation(-90, 180, 1), returnsNormally);
    for (final input in <List<num?>>[
      [1, null, null],
      [null, 1, null],
      [null, null, 1],
      [1, 1, null],
      [1, null, 1],
      [null, 1, 1],
      [91, 0, 1],
      [0, -181, 1],
      [double.nan, 0, 1],
      [0, double.infinity, 1],
      [0, 0, -1],
    ]) {
      expect(
        () => Rules.validateLocation(
          input[0]?.toDouble(),
          input[1]?.toDouble(),
          input[2]?.toInt(),
        ),
        throwsA(isA<RuleViolation>()),
      );
    }
  });
  test('rejects invalid choices outside the UI', () {
    for (final d in [
      valid()..carriage = 0,
      valid()..carriage = 7,
      valid()..component = 'bogus',
      valid()..priority = 'urgent',
      valid()..status = 'unknown',
    ]) {
      expect(() => Rules.prepare(d, null, 1), throwsA(isA<RuleViolation>()));
    }
  });
}
