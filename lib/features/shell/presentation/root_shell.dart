import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/widgets/app_bottom_nav.dart';
import '../../../routes/app_router.dart';
import '../../analytics/state/analytics_provider.dart';
import '../../chapters/presentation/topic_list_screen.dart';
import '../../chapters/state/chapter_provider.dart';
import '../../flashcards/state/flashcard_provider.dart';
import '../../analytics/presentation/stats_tab.dart';
import '../../chapters/presentation/chapters_tab.dart';
import '../../dashboard/presentation/dashboard_screen.dart';
import '../../flashcards/presentation/cards_tab.dart';
import '../../quiz/presentation/practice_tab.dart';

/// Root scaffold: IndexedStack keeps each tab's state alive while switching,
/// matching the HTML's 5-tab bottom navigation.
class RootShell extends StatefulWidget {
  const RootShell({super.key});

  @override
  State<RootShell> createState() => _RootShellState();
}

class _RootShellState extends State<RootShell> {
  int _index = 0;

  void goToTab(int index) {
    setState(() => _index = index);
    // Stats aggregates persisted history; refresh when the tab is shown.
    if (index == 3) context.read<AnalyticsProvider>().load();
    // Dashboard readiness/streak may have changed while studying.
    if (index == 0) context.read<ChapterProvider>().refreshProgress();
    // Re-evaluate the due queue whenever the Cards tab is opened.
    if (index == 4) context.read<FlashcardProvider>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            onNavigateToTab: goToTab,
            onOpenChapter: (chapterId) {
              final provider = context.read<ChapterProvider>();
              final chapter = provider.chapters
                  .where((c) => c.id == chapterId)
                  .firstOrNull;
              if (chapter == null) return;
              Navigator.of(context).pushNamed(
                AppRoutes.topics,
                arguments: TopicListArgs(chapter: chapter),
              );
            },
          ),
          const ChaptersTab(),
          const PracticeTab(),
          const StatsTab(),
          const CardsTab(),
        ],
      ),
      bottomNavigationBar:
          AppBottomNav(currentIndex: _index, onTap: goToTab),
    );
  }
}
