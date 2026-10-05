import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/loading_indicator.dart';
import '../../../core/widgets/section_header.dart';
import '../../../routes/app_router.dart';
import '../../chapters/domain/topic.dart';
import '../../formulas/domain/formula.dart';
import '../../quiz/domain/question.dart';
import '../../theory/presentation/theory_reader_screen.dart';
import '../domain/bookmark.dart';

/// All saved bookmarks, grouped by type.
class BookmarksScreen extends StatefulWidget {
  const BookmarksScreen({super.key});

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen> {
  bool _loading = true;
  String? _error;
  List<Question> _questions = [];
  List<Formula> _formulas = [];
  List<Topic> _topics = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final deps = context.read<AppDependencies>();
    try {
      final marks = await deps.bookmarkRepository.getAll();
      final questionIds = [
        for (final b in marks.where((b) => b.type == BookmarkType.question))
          b.itemId,
      ];
      final formulaIds = [
        for (final b in marks.where((b) => b.type == BookmarkType.formula))
          b.itemId,
      ];
      final topicIds = {
        for (final b in marks.where((b) => b.type == BookmarkType.topic))
          b.itemId,
      };
      final questions =
          await deps.questionRepository.getByIds(questionIds);
      final formulas = await deps.formulaRepository.getByIds(formulaIds);
      final topics = (await deps.chapterRepository.getAllTopics())
          .where((t) => topicIds.contains(t.id))
          .toList();
      if (!mounted) return;
      setState(() {
        _questions = questions;
        _formulas = formulas;
        _topics = topics;
        _error = null;
        _loading = false;
      });
    } catch (e) {
      debugPrint('BookmarksScreen._load: $e');
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _retry() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  Future<void> _remove(BookmarkType type, String id) async {
    await context
        .read<AppDependencies>()
        .bookmarkRepository
        .remove(type, id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEmpty =
        _questions.isEmpty && _formulas.isEmpty && _topics.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.bookmarks)),
      body: _loading
          ? const LoadingIndicator()
          : _error != null
          ? ErrorState(message: _error, onRetry: _retry)
          : isEmpty
              ? const EmptyState(
                  icon: Icons.bookmark_outline,
                  title: AppStrings.noBookmarks,
                  message: AppStrings.noBookmarksMessage,
                )
              : ListView(
                  padding: AppSpacing.screenPadding,
                  children: [
                    if (_topics.isNotEmpty) ...[
                      const SectionHeader(title: 'Topics'),
                      const SizedBox(height: AppSpacing.sm),
                      for (final topic in _topics)
                        _BookmarkTile(
                          icon: Icons.menu_book_outlined,
                          iconColor: colors.primary,
                          title: topic.title,
                          subtitle: topic.subtitle,
                          onOpen: () => Navigator.of(context).pushNamed(
                            AppRoutes.theory,
                            arguments: TheoryReaderArgs(topic: topic),
                          ),
                          onRemove: () =>
                              _remove(BookmarkType.topic, topic.id),
                        ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_questions.isNotEmpty) ...[
                      const SectionHeader(title: 'Questions'),
                      const SizedBox(height: AppSpacing.sm),
                      for (final question in _questions)
                        _BookmarkTile(
                          icon: Icons.quiz_outlined,
                          iconColor: colors.warning,
                          title: question.questionText,
                          subtitle: 'Answer: '
                              '${question.options[question.correctIndex]}',
                          onRemove: () =>
                              _remove(BookmarkType.question, question.id),
                        ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (_formulas.isNotEmpty) ...[
                      const SectionHeader(title: 'Formulas'),
                      const SizedBox(height: AppSpacing.sm),
                      for (final formula in _formulas)
                        _BookmarkTile(
                          icon: Icons.functions,
                          iconColor: colors.success,
                          title: formula.title,
                          subtitle: formula.plainText,
                          onOpen: () => Navigator.of(context).pushNamed(
                            AppRoutes.formulas,
                            arguments: formula.chapterId,
                          ),
                          onRemove: () =>
                              _remove(BookmarkType.formula, formula.id),
                        ),
                    ],
                  ],
                ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onOpen,
    required this.onRemove,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppCard(
        padding: AppSpacing.compactCardPadding,
        borderRadius: AppRadius.xlAll,
        onTap: onOpen,
        child: Row(
          children: [
            Icon(icon, size: 20, color: iconColor),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.bodyMedium
                          .copyWith(color: colors.textPrimary)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption
                          .copyWith(color: colors.textSecondary)),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Remove bookmark',
              icon: Icon(Icons.delete_outline,
                  size: 20, color: colors.textSecondary),
              onPressed: onRemove,
            ),
          ],
        ),
      ),
    );
  }
}
