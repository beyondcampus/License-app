import 'package:flutter_test/flutter_test.dart';

import 'helpers/test_deps.dart';

void main() {
  setUpAll(setUpTestDatabase);

  testWidgets('App boots to the dashboard with real content', (tester) async {
    await pumpApp(tester);

    expect(find.text('ExamPrep Pro'), findsOneWidget);
    expect(find.text('Overall Readiness'), findsOneWidget);
    // Real chapters from the Supabase snapshot in test/fixtures/content.
    expect(find.textContaining('Basic Electrical'), findsOneWidget);
  });
}
