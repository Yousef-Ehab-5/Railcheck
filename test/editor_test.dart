import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:railcheck/database/report.dart';
import 'package:railcheck/domain/rules.dart';
import 'package:railcheck/repositories/report_repository.dart';
import 'package:railcheck/screens/editor_screen.dart';
import 'package:railcheck/theme/app_theme.dart';

class FakeStore implements ReportStore {
  int writes = 0;
  @override
  Stream<List<Report>> watchAll() => Stream.value([]);
  @override
  Future<Report?> find(int id) async => null;
  @override
  Future<void> save(Draft draft, Report? original) async {
    Rules.prepare(draft, original, 1);
    writes++;
  }

  @override
  Future<void> delete(Report report) async {}
  @override
  Future<void> deleteAll() async {}
}

void main() {
  testWidgets('add screen validates empty form and survives narrow layout', (
    tester,
  ) async {
    final store = FakeStore();
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: railTheme(),
        home: EditorScreen(repository: store),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Save report'),
      400,
      scrollable: find
          .byWidgetPredicate(
            (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
          )
          .first,
    );
    await tester.tap(find.text('Save report'));
    await tester.pump();
    expect(store.writes, 0);
    expect(tester.takeException(), isNull);
  });
  testWidgets('unsaved back navigation can cancel or discard', (tester) async {
    final store = FakeStore();
    await tester.pumpWidget(
      MaterialApp(
        theme: railTheme(),
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => EditorScreen(repository: store),
                  ),
                );
              },
              child: const Text('Open editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open editor'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Train 205');
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Discard unsaved changes?'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Train 205'), findsOneWidget);
    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Discard'));
    await tester.pumpAndSettle();
    expect(find.text('Open editor'), findsOneWidget);
  });
}
