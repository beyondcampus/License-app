import 'package:flutter/material.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Syntax-highlighted code block matching the HTML `.code-block`:
/// dark inset background, mono font, horizontal scroll.
class CodeBlock extends StatelessWidget {
  const CodeBlock({super.key, required this.code, this.language = 'cpp'});

  final String code;

  /// highlight.js language id: `c`, `cpp`, `x86asm`, ...
  final String language;

  static const _languageAliases = {
    'c++': 'cpp',
    'c': 'cpp',
    'assembly': 'x86asm',
    'asm': 'x86asm',
    // Transition tables, traces and pseudo-code in the theory content.
    'text': 'plaintext',
    'plain': 'plaintext',
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Use the highlight theme's token colors but our own background.
    final baseTheme = isDark ? atomOneDarkTheme : atomOneLightTheme;
    final theme = Map<String, TextStyle>.of(baseTheme);
    theme['root'] = (theme['root'] ?? const TextStyle())
        .copyWith(backgroundColor: Colors.transparent, color: colors.codeText);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: colors.codeBackground,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: colors.border),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: HighlightView(
          code.trim(),
          language: _languageAliases[language.toLowerCase()] ?? language,
          theme: theme,
          textStyle: AppTypography.code,
        ),
      ),
    );
  }
}
