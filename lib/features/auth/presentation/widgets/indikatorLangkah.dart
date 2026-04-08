import 'package:flutter/material.dart';

import '../../../../core/theme/temaAplikasi.dart';

class StepIndicator extends StatefulWidget {
  final int currentStep;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.labels = const ['Buat Akun', 'Kata Sandi', 'Foto Profil', 'Sukses'],
  });

  @override
  State<StepIndicator> createState() => _StepIndicatorState();
}

class _StepIndicatorState extends State<StepIndicator> {
  bool _animate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _animate = true;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStepNumber = widget.currentStep + 1;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(widget.labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final beforeStep = (index ~/ 2) + 1;
            final isActive = _animate && currentStepNumber > beforeStep;
            return _buildLine(isActive, colorScheme);
          }

          final step = (index ~/ 2) + 1;
          final isActive = _animate && currentStepNumber >= step;
          return _buildStep(
            step,
            widget.labels[step - 1],
            isActive,
            colorScheme,
          );
        }),
      ),
    );
  }

  Widget _buildStep(
    int step,
    String label,
    bool isActive,
    ColorScheme colorScheme,
  ) {
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedScale(
            scale: isActive ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary
                    : colorScheme.outline.withValues(alpha: 0.65),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    color: isActive
                        ? AppColors.textOnPrimary
                        : colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                  child: Text('$step'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              color: isActive
                  ? colorScheme.onSurface
                  : colorScheme.onSurface.withValues(alpha: 0.72),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLine(bool isActive, ColorScheme colorScheme) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: colorScheme.outline.withValues(alpha: 0.55)),
            AnimatedAlign(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: isActive ? 1 : 0,
                child: Container(color: AppColors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
