import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/languageProvider.dart';

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  static const List<({String code, String label})> _options = [
    (code: 'id', label: 'Bahasa Indonesia'),
    (code: 'en', label: 'English'),
    (code: 'zh', label: '中文'),
    (code: 'ms', label: 'Bahasa Melayu'),
    (code: 'ja', label: '日本語'),
    (code: 'hi', label: 'हिन्दी'),
    (code: 'es', label: 'Español'),
    (code: 'fr', label: 'Français'),
    (code: 'jv', label: 'Basa Jawa'),
    (code: 'min', label: 'Baso Minang'),
    (code: 'su', label: 'Basa Sunda'),
    (code: 'btk', label: 'Hata Batak'),
    (code: 'mnd', label: 'Bahasa Manado'),
  ];

  String _normalizeLabel(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCode = context.watch<LanguageProvider>().locale.languageCode;
    final selectedOption = _options.firstWhere(
      (option) => option.code == selectedCode,
      orElse: () => _options.first,
    );

    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: PopupMenuButton<String>(
        initialValue: selectedCode,
        tooltip: '',
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        constraints: const BoxConstraints(minWidth: 0),
        onSelected: (value) {
          context.read<LanguageProvider>().changeLanguage(value);
        },
        itemBuilder: (context) {
          return _options
              .map(
                (option) => PopupMenuItem<String>(
                  value: option.code,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _normalizeLabel(option.label),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(growable: false);
        },
        child: Padding(
          padding: const EdgeInsets.only(left: 12, right: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _normalizeLabel(selectedOption.label),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: colorScheme.onSurface,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
