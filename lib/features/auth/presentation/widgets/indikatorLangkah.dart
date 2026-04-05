import 'package:flutter/material.dart';

import '../../../../core/theme/temaAplikasi.dart';

class StepIndicator extends StatefulWidget {
  final int currentStep;
  final List<String> labels;

  const StepIndicator({
    super.key,
    required this.currentStep,
    this.labels = const ['Buat Akun', 'Foto Profil', 'Selesai'],
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

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: List.generate(widget.labels.length * 2 - 1, (index) {
          if (index.isOdd) {
            final beforeStep = (index ~/ 2) + 1;
            final isActive = _animate && currentStepNumber > beforeStep;
            return _buildLine(isActive);
          }

          final step = (index ~/ 2) + 1;
          final isActive = _animate && currentStepNumber >= step;
          return _buildStep(step, widget.labels[step - 1], isActive);
        }),
      ),
    );
  }

  Widget _buildStep(int step, String label, bool isActive) {
    return Column(
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
              color: isActive ? AppColors.primary : AppColors.borderColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                style: TextStyle(
                  color: isActive
                      ? AppColors.textOnPrimary
                      : AppColors.primaryText,
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
            fontSize: 12,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            color: isActive ? AppColors.primaryText : AppColors.secondaryText,
          ),
          child: Text(label),
        ),
      ],
    );
  }

  Widget _buildLine(bool isActive) {
    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        height: 4,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.borderColor),
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
