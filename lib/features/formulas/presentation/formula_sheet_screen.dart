import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/services/app_dependencies.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/code_block.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/error_state.dart';
import '../../../core/widgets/formula_block.dart';
import '../../bookmarks/domain/bookmark.dart';
import '../../chapters/state/chapter_provider.dart';
import '../domain/formula.dart';

/// Formula cheatsheet (HTML screen 5): chapter selection, local search and
/// bookmarkable formula cards.
class FormulaSheetScreen extends StatefulWidget {
  const FormulaSheetScreen({super.key, this.initialChapterId});

  final String? initialChapterId;

  @override
  State<FormulaSheetScreen> createState() => _FormulaSheetScreenState();
}

class _FormulaSheetScreenState extends State<FormulaSheetScreen> {
  final _scrollController = ScrollController();
  String? _selectedChapterId;
  String _query = '';
  List<Formula> _all = [];
  Set<String> _bookmarked = {};
  bool _loading = true;
  bool _showFilters = true;
  double _lastScrollOffset = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    final chapters = context.read<ChapterProvider>().chapters;
    _selectedChapterId =
        widget.initialChapterId != null &&
            chapters.any((c) => c.id == widget.initialChapterId)
        ? widget.initialChapterId
        : chapters.firstOrNull?.id;
    _scrollController.addListener(_handleScroll);
    _load();
  }

  void _handleScroll() {
    final offset = _scrollController.offset;
    final shouldShow = offset <= 0 || offset < _lastScrollOffset;
    if (shouldShow != _showFilters && mounted) {
      setState(() => _showFilters = shouldShow);
    }
    _lastScrollOffset = offset;
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_handleScroll)
      ..dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final deps = context.read<AppDependencies>();
    try {
      final all = _selectedChapterId == null
          ? await deps.formulaRepository.getAll()
          : await deps.formulaRepository.getByChapter(_selectedChapterId!);
      final marks = await deps.bookmarkRepository.getByType(
        BookmarkType.formula,
      );
      if (!mounted) return;
      setState(() {
        _all = all;
        _bookmarked = marks.map((b) => b.itemId).toSet();
        _loading = false;
      });
    } catch (e) {
      debugPrint('FormulaSheetScreen._load: $e');
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

  Future<void> _toggleBookmark(Formula formula) async {
    final deps = context.read<AppDependencies>();
    final nowMarked = await deps.bookmarkRepository.toggle(
      BookmarkType.formula,
      formula.id,
    );
    if (!mounted) return;
    setState(() {
      if (nowMarked) {
        _bookmarked.add(formula.id);
      } else {
        _bookmarked.remove(formula.id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final chapters = context.watch<ChapterProvider>().chapters;
    final chapterId = _selectedChapterId;

    final query = _query.trim().toLowerCase();
    final visible = _all.where((f) {
      if (chapterId != null && f.chapterId != chapterId) return false;
      if (query.isEmpty) return true;
      return f.title.toLowerCase().contains(query) ||
          f.plainText.toLowerCase().contains(query) ||
          f.description.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.formulaCheatsheet)),
      body: Column(
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            child: _showFilters
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Column(
                      children: [
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search formulas...',
                            prefixIcon: Icon(Icons.search, size: 20),
                          ),
                          style: AppTypography.body.copyWith(
                            color: colors.textPrimary,
                          ),
                          onChanged: (value) => setState(() => _query = value),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (chapters.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          AppCard(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            borderRadius: AppRadius.lgAll,
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value:
                                    chapters.any(
                                      (c) => c.id == _selectedChapterId,
                                    )
                                    ? _selectedChapterId
                                    : chapters.first.id,
                                isExpanded: true,
                                icon: const Icon(Icons.keyboard_arrow_down),
                                hint: const Text('Select chapter'),
                                items: [
                                  for (final chapter in chapters)
                                    DropdownMenuItem(
                                      value: chapter.id,
                                      child: Text(
                                        'Chapter ${chapter.order}: ${chapter.title}',
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                ],
                                onChanged: (chapterId) {
                                  if (chapterId == null ||
                                      chapterId == _selectedChapterId) {
                                    return;
                                  }
                                  setState(() {
                                    _selectedChapterId = chapterId;
                                    _loading = true;
                                    _error = null;
                                  });
                                  _scrollController.jumpTo(0);
                                  _load();
                                },
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? ErrorState(message: _error, onRetry: _retry)
                : visible.isEmpty
                ? EmptyState(
                    icon: Icons.functions,
                    title: AppStrings.noResults,
                    message: query.isEmpty
                        ? 'No formulas for this chapter yet.'
                        : 'No formulas match "$_query".',
                  )
                : ListView.separated(
                    controller: _scrollController,
                    padding: AppSpacing.screenPadding,
                    itemCount: visible.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.md),
                    itemBuilder: (context, index) {
                      final formula = visible[index];
                      final marked = _bookmarked.contains(formula.id);
                      return AppCard(
                        padding: AppSpacing.compactCardPadding,
                        borderRadius: AppRadius.xlAll,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    '${index + 1}.',
                                    style: AppTypography.meta.copyWith(
                                      color: colors.primary,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    formula.title,
                                    style: AppTypography.meta.copyWith(
                                      color: colors.textSecondary,
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => _toggleBookmark(formula),
                                  child: Icon(
                                    marked
                                        ? Icons.bookmark
                                        : Icons.bookmark_border,
                                    size: 18,
                                    color: marked
                                        ? colors.primary
                                        : colors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            if (formula.isCode)
                              CodeBlock(
                                code: formula.plainText,
                                language: 'cpp',
                              )
                            else
                              FormulaBlock(
                                latex: formula.latex,
                                plainText: formula.plainText,
                              ),
                            if (formula.description.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                formula.description,
                                style: AppTypography.caption.copyWith(
                                  color: colors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
