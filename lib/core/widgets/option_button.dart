import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../theme/app_theme.dart';

/// Visual state of a quiz option (HTML `.option-btn` + derived states).
enum OptionState { idle, selected, correct, incorrect, disabled }

/// Quiz answer option. Correctness is communicated with BOTH color and an
/// icon/text so it never relies on color alone (accessibility requirement).
class OptionButton extends StatelessWidget {
  const OptionButton({
    super.key,
    required this.label,
    required this.state,
    this.onTap,
  });

  final String label;
  final OptionState state;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Color background = colors.background;
    Color border = colors.border;
    Color text = colors.textPrimary;
    Widget trailing = Icon(Icons.radio_button_unchecked,
        size: 18, color: colors.textSecondary);
    String? semanticsHint;

    switch (state) {
      case OptionState.idle:
        break;
      case OptionState.selected:
        border = colors.primary;
        background = colors.primaryFill;
        trailing =
            Icon(Icons.radio_button_checked, size: 18, color: colors.primary);
        semanticsHint = 'Selected';
      case OptionState.correct:
        background = colors.correctFill;
        border = colors.success;
        text = colors.correctText;
        trailing = Icon(Icons.check_circle, size: 18, color: colors.success);
        semanticsHint = 'Correct answer';
      case OptionState.incorrect:
        background = colors.incorrectFill;
        border = colors.error;
        text = colors.incorrectText;
        trailing = Icon(Icons.cancel, size: 18, color: colors.error);
        semanticsHint = 'Incorrect answer';
      case OptionState.disabled:
        text = colors.textSecondary;
        trailing = const SizedBox(width: 18);
    }

    return Semantics(
      button: true,
      hint: semanticsHint,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.lgAll,
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppRadius.lgAll,
              border: Border.all(color: border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: AppTypography.body.copyWith(color: text)),
                ),
                const SizedBox(width: AppSpacing.sm),
                trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
