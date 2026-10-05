import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Centered formula display matching the HTML `.formula-math`: inset dark
/// background, dashed border, accent-blue math.
///
/// Renders LaTeX via flutter_math_fork; on parse failure (or when only plain
/// text is provided) it falls back to monospace text, so a bad formula can
/// never crash a screen.
class FormulaBlock extends StatelessWidget {
  const FormulaBlock({super.key, this.latex, this.plainText})
      : assert(latex != null || plainText != null,
            'FormulaBlock needs latex or plainText');

  final String? latex;
  final String? plainText;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fallbackStyle =
        AppTypography.formula.copyWith(color: colors.formulaText);

    Widget content;
    if (latex != null && latex!.trim().isNotEmpty) {
      content = Math.tex(
        latex!,
        textStyle: TextStyle(fontSize: 16, color: colors.formulaText),
        onErrorFallback: (_) => Text(
          plainText ?? latex!,
          style: fallbackStyle,
          textAlign: TextAlign.center,
        ),
      );
    } else {
      content = Text(plainText!, style: fallbackStyle,
          textAlign: TextAlign.center);
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border, style: BorderStyle.solid),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Center(child: content),
      ),
    );
  }
}
