import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:railcheck/controllers/write_controller.dart';
import 'package:railcheck/domain/rules.dart';

void main() {
  test('repeated submit performs exactly one write', () async {
    final c = WriteController();
    final gate = Completer<void>();
    var calls = 0;
    Future<void> save() {
      calls++;
      return gate.future;
    }

    final first = c.run(save);
    expect(c.busy, isTrue);
    expect(await c.run(save), isFalse);
    expect(calls, 1);
    gate.complete();
    expect(await first, isTrue);
    expect(c.busy, isFalse);
    c.dispose();
  });
  test('failed submission releases guard and permits retry', () async {
    final c = WriteController();
    expect(
      await c.run(() async {
        throw const RuleViolation('Validation failed');
      }),
      isFalse,
    );
    expect(c.error, 'Validation failed');
    expect(c.busy, isFalse);
    expect(await c.run(() async {}), isTrue);
    expect(c.error, isNull);
    c.dispose();
  });
  test('completion after disposal does not notify', () async {
    final c = WriteController();
    final gate = Completer<void>();
    final result = c.run(() => gate.future);
    c.dispose();
    gate.complete();
    expect(await result, isTrue);
  });
}
