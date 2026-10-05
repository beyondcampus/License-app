import 'package:exam_prep_pro/core/constants/app_colors.dart';
import 'package:exam_prep_pro/core/theme/app_theme.dart';
import 'package:exam_prep_pro/core/widgets/app_buttons.dart';
import 'package:exam_prep_pro/core/widgets/app_card.dart';
import 'package:exam_prep_pro/core/widgets/app_tab_group.dart';
import 'package:exam_prep_pro/core/widgets/badges.dart';
import 'package:exam_prep_pro/core/widgets/code_block.dart';
import 'package:exam_prep_pro/core/widgets/empty_state.dart';
import 'package:exam_prep_pro/core/widgets/error_state.dart';
import 'package:exam_prep_pro/core/widgets/explanation_box.dart';
import 'package:exam_prep_pro/core/widgets/formula_block.dart';
import 'package:exam_prep_pro/core/widgets/option_button.dart';
import 'package:exam_prep_pro/core/widgets/progress_card.dart';
import 'package:exam_prep_pro/core/widgets/subject_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {required bool dark}) {
  return MaterialApp(
    theme: dark ? AppTheme.dark() : AppTheme.light(),
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );
}

void main() {
  group('Design tokens', () {
    test('dark theme uses the HTML palette', () {
      final theme = AppTheme.dark();
      final c = theme.extension<AppColorsExtension>()!;
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0F172A));
      expect(c.surface, const Color(0xFF1E293B));
      expect(c.primary, const Color(0xFF3B82F6));
      expect(c.success, const Color(0xFF22C55E));
      expect(c.warning, const Color(0xFFF97316));
      expect(c.border, const Color(0xFF334155));
      expect(c.codeBackground, const Color(0xFF090D16));
      expect(c.navBackground, const Color(0xFF0B1329));
      expect(c.textPrimary, const Color(0xFFF8FAFC));
      expect(c.textSecondary, const Color(0xFF94A3B8));
    });

    test('light theme keeps accent hues but flips surfaces', () {
      final theme = AppTheme.light();
      final c = theme.extension<AppColorsExtension>()!;
      expect(c.primary, const Color(0xFF3B82F6));
      expect(c.surface, const Color(0xFFFFFFFF));
      expect(theme.brightness, Brightness.light);
    });
  });

  group('Core widgets render in both themes', () {
    final sample = Column(
      children: [
        const ProgressCard(label: 'Overall Readiness', value: 0.68),
        AppCard(child: const Text('card')),
        AppTabGroup(
            tabs: const ['Concepts', 'Formulas', 'Notes'],
            selectedIndex: 0,
            onChanged: (_) {}),
        const OptionButton(label: 'A. 20050H', state: OptionState.idle),
        const OptionButton(label: 'B. 20005H', state: OptionState.correct),
        const OptionButton(label: 'C. 200500H', state: OptionState.incorrect),
        const OptionButton(label: 'D. 2005H', state: OptionState.selected),
        const ExplanationBox(title: 'Explanation', text: 'PA = CS*10H + IP'),
        const CodeBlock(code: 'int *p = &x;', language: 'cpp'),
        const FormulaBlock(
            latex: r'f_r = \frac{1}{2\pi\sqrt{LC}}',
            plainText: 'fr = 1/(2pi sqrt(LC))'),
        const FormulaBlock(plainText: 'V = IR'),
        const StreakBadge(days: 5),
        const TimerBadge(label: '0:28'),
        const InfoChip(label: 'Formulas', icon: Icons.functions),
        ActionRow(children: [
          SecondaryButton(label: 'Bookmark', onPressed: () {}),
          PrimaryButton(label: 'Next Question', onPressed: () {}),
        ]),
        SubjectCard(
          title: 'Chap 1: Basic Electrical & EDC',
          emoji: '⚡',
          meta: '12 Topics • 75 MCQs • Formula Sheet',
          progress: 0.4,
          onTap: () {},
        ),
      ],
    );

    for (final dark in [true, false]) {
      testWidgets('theme dark=$dark renders without errors', (tester) async {
        await tester.pumpWidget(_wrap(sample, dark: dark));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Overall Readiness'), findsOneWidget);
        expect(find.text('B. 20005H'), findsOneWidget);
        // Correct/incorrect communicated by icon as well as color.
        expect(find.byIcon(Icons.check_circle), findsOneWidget);
        expect(find.byIcon(Icons.cancel), findsOneWidget);
        expect(find.text('🔥 5 Days'), findsOneWidget);
      });
    }

    testWidgets('empty and error states render', (tester) async {
      await tester.pumpWidget(_wrap(
          Column(children: [
            const EmptyState(
                icon: Icons.bookmark_outline,
                title: 'Nothing bookmarked yet',
                message: 'Bookmark things to find them here.'),
            ErrorState(message: 'Bad data', onRetry: () {}),
          ]),
          dark: true));
      await tester.pumpAndSettle();
      expect(find.text('Nothing bookmarked yet'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('tab group switches selection', (tester) async {
      var selected = 0;
      await tester.pumpWidget(_wrap(
          StatefulBuilder(builder: (context, setState) {
            return AppTabGroup(
              tabs: const ['Theory', 'Practice'],
              selectedIndex: selected,
              onChanged: (i) => setState(() => selected = i),
            );
          }),
          dark: true));
      await tester.tap(find.text('Practice'));
      await tester.pumpAndSettle();
      expect(selected, 1);
    });

    testWidgets('invalid LaTeX falls back to plain text without crashing',
        (tester) async {
      await tester.pumpWidget(_wrap(
          const FormulaBlock(latex: r'\frac{unclosed', plainText: 'V = IR'),
          dark: true));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('V = IR'), findsOneWidget);
    });
  });
}
