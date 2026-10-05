import 'package:exam_prep_pro/core/services/app_dependencies.dart';
import 'package:exam_prep_pro/core/services/content_source.dart';
import 'package:exam_prep_pro/core/services/prefs_service.dart';
import 'package:exam_prep_pro/features/dashboard/presentation/dashboard_screen.dart';
import 'package:exam_prep_pro/main.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'fixture_content.dart';

/// Points sqflite at the ffi implementation so repositories run in plain
/// `flutter test` on the host machine. The no-isolate variant is required:
/// widget tests run under a fake-async clock, and responses from a background
/// isolate would never be delivered, deadlocking pumpAndSettle.
void setUpTestDatabase() {
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfiNoIsolate;
}

/// Builds the full dependency graph on an in-memory database + mock prefs.
/// Study content comes from [content] in place of Supabase — by default the
/// snapshot in test/fixtures/content.
Future<AppDependencies> buildTestDeps(
    {Map<String, Object> prefs = const {}, ContentBackend? content}) async {
  SharedPreferences.setMockInitialValues(prefs);
  return AppDependencies(
    prefs: await PrefsService.init(),
    dbPath: inMemoryDatabasePath,
    contentBackend: content ?? FixtureContentBackend.snapshot(),
  );
}

/// Pumps the real app over test dependencies and waits for the dashboard.
///
/// The database is closed on teardown: sqflite caches open databases by path
/// (singleInstance), so a leaked in-memory DB from one test would be handed to
/// the next test bound to a dead fake-async zone and deadlock it.
Future<AppDependencies> pumpApp(WidgetTester tester,
    {Map<String, Object> prefs = const {}, ContentBackend? content}) async {
  final deps = await buildTestDeps(prefs: prefs, content: content);
  addTearDown(deps.dbHelper.close);
  await tester.pumpWidget(ExamPrepApp(deps: deps));
  await tester.pumpAndSettle();
  return deps;
}

/// Simulates an app restart: pumps a brand-new app over the SAME
/// dependencies (same database and preferences), as a device restart would.
Future<void> restartApp(WidgetTester tester, AppDependencies deps) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();
  await tester.pumpWidget(ExamPrepApp(deps: deps));
  await tester.pumpAndSettle();
}

/// Chapter 1 is a topic → subtopic tree: opens the first group so that
/// "1.1.1 Ohm's Law & Basic Concepts" is on screen. Call after the chapter's
/// topic list is showing.
Future<void> openBasicConceptsGroup(WidgetTester tester) async {
  await tester.tap(find.textContaining('1.1 Basic Concepts'));
  await tester.pumpAndSettle();
}

/// Taps a dashboard quick action by label. The dashboard is a lazy ListView
/// and the quick-action rows sit below the fold of the test viewport, so they
/// are not built until scrolled into view.
Future<void> tapQuickAction(WidgetTester tester, String label) async {
  final dashboardList = find.descendant(
    of: find.byType(DashboardScreen),
    matching: find.byType(Scrollable),
  );
  await tester.scrollUntilVisible(find.text(label), 200,
      scrollable: dashboardList.first);
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
