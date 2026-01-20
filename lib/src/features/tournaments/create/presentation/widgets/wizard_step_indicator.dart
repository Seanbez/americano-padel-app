import 'package:flutter/material.dart';

class WizardStepIndicator extends StatelessWidget {
  const WizardStepIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepTitles,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepTitles;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final isCompleted = index < currentStep;
          final isCurrent = index == currentStep;
          final isLast = index == totalSteps - 1;

          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _StepCircle(
                        stepNumber: index + 1,
                        isCompleted: isCompleted,
                        isCurrent: isCurrent,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        stepTitles[index],
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isCurrent
                                  ? colorScheme.primary
                                  : isCompleted
                                      ? colorScheme.onSurface
                                      : colorScheme.onSurfaceVariant,
                              fontWeight:
                                  isCurrent ? FontWeight.w600 : FontWeight.normal,
                            ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      height: 2,
                      margin: const EdgeInsets.only(bottom: 16),
                      color: isCompleted
                          ? colorScheme.primary
                          : colorScheme.outlineVariant,
                    ),
                  ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class _StepCircle extends StatelessWidget {
  const _StepCircle({
    required this.stepNumber,
    required this.isCompleted,
    required this.isCurrent,
  });

  final int stepNumber;
  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;
    Widget child;

    if (isCompleted) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      child = Icon(Icons.check, size: 16, color: foregroundColor);
    } else if (isCurrent) {
      backgroundColor = colorScheme.primary;
      foregroundColor = colorScheme.onPrimary;
      child = Text(
        '$stepNumber',
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      );
    } else {
      backgroundColor = colorScheme.surfaceContainerHighest;
      foregroundColor = colorScheme.onSurfaceVariant;
      child = Text(
        '$stepNumber',
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w500,
          fontSize: 12,
        ),
      );
    }

    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
      ),
      child: Center(child: child),
    );
  }
}
