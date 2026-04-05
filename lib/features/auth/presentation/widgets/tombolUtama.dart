import 'package:flutter/material.dart';

import '../../../../core/theme/temaAplikasi.dart';

class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final IconData? icon;

  const PrimaryButton({super.key, required this.text, this.onPressed, this.isLoading = false, this.isOutlined = false, this.icon});

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(isOutlined ? AppColors.primaryText : AppColors.textOnPrimary)))
        : icon != null
            ? Row(mainAxisSize: MainAxisSize.min, children: [Text(text), const SizedBox(width: 8), Icon(icon, size: 20)])
            : Text(text);

    if (isOutlined) {
      return SizedBox(width: double.infinity, height: 52, child: OutlinedButton(onPressed: isLoading ? null : onPressed, child: child));
    }
    return SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: isLoading ? null : onPressed, child: child));
  }
}
