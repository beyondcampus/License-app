import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/code_block.dart';
import '../../../core/widgets/formula_block.dart';
import '../domain/theory_content.dart';

/// Renders one [TheoryBlock] according to its type. Unknown/empty content
/// renders as nothing rather than crashing.
class TheoryBlockView extends StatelessWidget {
  const TheoryBlockView({super.key, required this.block});

  final TheoryBlock block;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    switch (block.type) {
      case TheoryBlockType.heading:
        return Padding(
          padding: const EdgeInsets.only(top: AppSpacing.xs),
          child: Text(block.text,
              style: AppTypography.sectionTitle
                  .copyWith(color: colors.textPrimary)),
        );
      case TheoryBlockType.paragraph:
        return Text(block.text,
            style: AppTypography.body.copyWith(color: colors.textSecondary));
      case TheoryBlockType.bulletList:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (block.text.isNotEmpty) ...[
              Text(block.text,
                  style:
                      AppTypography.body.copyWith(color: colors.textSecondary)),
              const SizedBox(height: AppSpacing.xs),
            ],
            for (final item in block.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('•  ',
                        style: AppTypography.body
                            .copyWith(color: colors.primary)),
                    Expanded(
                      child: Text(item,
                          style: AppTypography.body
                              .copyWith(color: colors.textSecondary)),
                    ),
                  ],
                ),
              ),
          ],
        );
      case TheoryBlockType.formula:
        return FormulaBlock(latex: block.latex, plainText: block.plainText);
      case TheoryBlockType.code:
        return CodeBlock(code: block.text, language: block.language ?? 'cpp');
      case TheoryBlockType.table:
        return _TheoryTable(rows: block.rows);
      case TheoryBlockType.note:
        return _CalloutBox(
          icon: Icons.info_outline,
          color: colors.primary,
          textColor: colors.explanationText,
          fill: colors.explanationFill,
          text: block.text,
        );
      case TheoryBlockType.warning:
        return _CalloutBox(
          icon: Icons.warning_amber_rounded,
          color: colors.warning,
          textColor: colors.warning,
          fill: colors.streakFill,
          text: block.text,
        );
      case TheoryBlockType.examTip:
        return _CalloutBox(
          icon: Icons.school_outlined,
          color: colors.success,
          textColor: colors.correctText,
          fill: colors.correctFill,
          text: block.text,
          label: 'Exam Tip',
        );
    }
  }
}

class _CalloutBox extends StatelessWidget {
  const _CalloutBox({
    required this.icon,
    required this.color,
    required this.textColor,
    required this.fill,
    required this.text,
    this.label,
  });

  final IconData icon;
  final Color color;
  final Color textColor;
  final Color fill;
  final String text;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label != null) ...[
                  Text(label!,
                      style:
                          AppTypography.metaBold.copyWith(color: textColor)),
                  const SizedBox(height: 2),
                ],
                Text(text,
                    style: AppTypography.meta.copyWith(color: textColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TheoryTable extends StatelessWidget {
  const _TheoryTable({required this.rows});

  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (rows.isEmpty) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: AppRadius.mdAll,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 320),
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            border: TableBorder.all(color: colors.border),
            children: [
              for (var r = 0; r < rows.length; r++)
                TableRow(
                  decoration: BoxDecoration(
                    color: r == 0 ? colors.codeBackground : colors.surface,
                  ),
                  children: [
                    for (final cell in rows[r])
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        child: Text(
                          cell,
                          style: r == 0
                              ? AppTypography.metaBold
                                  .copyWith(color: colors.textPrimary)
                              : AppTypography.meta
                                  .copyWith(color: colors.textSecondary),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
