import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/math_utils.dart';
import '../../../core/widgets/badges.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/progress_card.dart';
import '../../../core/widgets/section_header.dart';
import '../../../core/widgets/subject_card.dart';
import '../../../routes/app_router.dart';
import '../../chapters/state/chapter_provider.dart';
import '../../auth/state/auth_provider.dart';

/// Home tab, matching the HTML dashboard: profile app bar with streak,
/// readiness progress, subject modules and quick actions.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({
    super.key,
    required this.onNavigateToTab,
    this.onOpenChapter,
  });

  final ValueChanged<int> onNavigateToTab;
  final ValueChanged<String>? onOpenChapter;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<ChapterProvider>();

    return Column(
      children: [
        _DashboardAppBar(streak: provider.userProgress.streak),
        Expanded(
          child: switch (provider.state) {
            LoadState.initial ||
            LoadState.loading =>
              const LoadingIndicator(),
            LoadState.error => ErrorState(
                message: provider.errorMessage,
                onRetry: () => context.read<ChapterProvider>().load(),
              ),
            LoadState.ready => ListView(
                padding: AppSpacing.screenPadding,
                children: [
                  ProgressCard(
                    label: AppStrings.overallReadiness,
                    value: provider.userProgress.readiness,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const SectionHeader(title: AppStrings.selectSubjectModule),
                  const SizedBox(height: AppSpacing.md),
                  for (final chapter in provider.chapters) ...[
                    SubjectCard(
                      title:
                          'Chap ${chapter.order}: ${chapter.title}',
                      emoji: chapter.emoji,
                      meta: _chapterMeta(provider, chapter.id),
                      progress: provider.chapterCompletion(chapter.id),
                      onTap: () => onOpenChapter != null
                          ? onOpenChapter!(chapter.id)
                          : onNavigateToTab(1),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  const SectionHeader(title: AppStrings.quickActions),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.edit_note,
                          label: AppStrings.practiceCenter,
                          color: colors.primary,
                          onTap: () => onNavigateToTab(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.insights,
                          label: AppStrings.resultsAndAnalytics,
                          color: colors.success,
                          onTap: () => onNavigateToTab(3),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.style,
                          label: AppStrings.flashcards,
                          color: colors.warning,
                          onTap: () => onNavigateToTab(4),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.functions,
                          label: AppStrings.formulaSheet,
                          color: colors.formulaText,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.formulas),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.bookmark_outline,
                          label: AppStrings.bookmarks,
                          color: colors.error,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.bookmarks),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _QuickAction(
                          icon: Icons.search,
                          label: AppStrings.search,
                          color: colors.textSecondary,
                          onTap: () => Navigator.of(context)
                              .pushNamed(AppRoutes.search),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          },
        ),
        // Ads disabled temporarily.
        // const AdBannerSlot(),
      ],
    );
  }

  String _chapterMeta(ChapterProvider provider, String chapterId) {
    final stats = provider.statsByChapter[chapterId];
    final done = MathUtils.percent(
        provider.chapterCompletion(chapterId), 1);
    final topicCount = provider.topicCountByChapter[chapterId] ??
        stats?.topicCount ??
        0;
    final mcqText = stats == null ? '' : ' • ${stats.questionCount} ${AppStrings.mcqs}';
    return '$topicCount ${AppStrings.topics}$mcqText • $done% done';
  }
}

class _DashboardAppBar extends StatelessWidget {
  const _DashboardAppBar({required this.streak});

  final int streak;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final auth = context.watch<AuthProvider?>();
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: () => Navigator.of(context).pushNamed(AppRoutes.profile),
                child: CircleAvatar(
                  radius: 17,
                  backgroundColor: colors.primary,
                  child: Text(_initial(auth),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InkWell(
                      onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.profile),
                      child: Text(_displayName(auth),
                        style: AppTypography.bodyMedium.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              StreakBadge(days: streak),
              const SizedBox(width: AppSpacing.xs),
              Consumer<ThemeProvider>(
                builder: (context, theme, _) => IconButton(
                  tooltip: 'Toggle theme',
                  onPressed: theme.toggle,
                  icon: Icon(
                    theme.isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 20,
                    color: colors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _displayName(AuthProvider? auth) {
    final metadata = auth?.user?.userMetadata;
    final name = metadata?['full_name']?.toString().trim();
    if (name != null && name.isNotEmpty) return name;

    final email = auth?.user?.email;
    if (email != null && email.isNotEmpty) return email;
    return AppStrings.appName;
  }

  String _initial(AuthProvider? auth) {
    final name = _displayName(auth).trim();
    return name.isEmpty ? 'E' : name[0].toUpperCase();
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppRadius.xxlAll,
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: AppRadius.xxlAll,
            border: Border.all(color: colors.border),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption
                      .copyWith(color: colors.textPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}
