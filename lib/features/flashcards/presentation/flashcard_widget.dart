import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/theme/app_theme.dart';

/// Tall flashcard with a 3D horizontal flip animation (HTML `.flashcard`).
class FlashcardWidget extends StatelessWidget {
  const FlashcardWidget({
    super.key,
    required this.topicLabel,
    required this.front,
    required this.back,
    required this.isFlipped,
    required this.onTap,
  });

  final String topicLabel;
  final String front;
  final String back;
  final bool isFlipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: isFlipped ? 'Answer: $back' : 'Question: $front',
      hint: isFlipped ? AppStrings.tapToFlipBack : AppStrings.tapToReveal,
      child: GestureDetector(
        onTap: onTap,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: isFlipped ? 1 : 0),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut,
          builder: (context, value, _) {
            final angle = value * math.pi;
            final showBack = value > 0.5;
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0012)
                ..rotateY(angle),
              child: Transform(
                alignment: Alignment.center,
                // Un-mirror the content once the back side is facing us.
                transform: Matrix4.identity()
                  ..rotateY(showBack ? math.pi : 0),
                child: _CardFace(
                  topicLabel: topicLabel,
                  text: showBack ? back : front,
                  hint: showBack
                      ? AppStrings.tapToFlipBack
                      : AppStrings.tapToReveal,
                  isBack: showBack,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.topicLabel,
    required this.text,
    required this.hint,
    required this.isBack,
  });

  final String topicLabel;
  final String text;
  final String hint;
  final bool isBack;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      constraints: const BoxConstraints(minHeight: 240),
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppRadius.flashcardAll,
        border: Border.all(
            color: isBack ? colors.primary : colors.border),
        boxShadow: AppElevation.flashcardShadow,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            topicLabel.toUpperCase(),
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: colors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            text,
            textAlign: TextAlign.center,
            style: isBack
                ? AppTypography.body.copyWith(
                    color: colors.textPrimary, fontSize: 14, height: 1.5)
                : AppTypography.flashcardQuestion
                    .copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(hint,
              style: AppTypography.meta
                  .copyWith(color: colors.textSecondary)),
        ],
      ),
    );
  }
}
