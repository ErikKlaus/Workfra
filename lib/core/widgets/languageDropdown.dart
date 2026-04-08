import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../localization/languageProvider.dart';

class LanguageDropdown extends StatelessWidget {
  const LanguageDropdown({super.key});

  static const List<({String code, String label})> _options = [
    (code: 'id', label: 'Indonesia'),
    (code: 'en', label: 'English'),
    (code: 'zh', label: 'Mandarin'),
    (code: 'ms', label: 'Melayu'),
  ];

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedCode = context.watch<LanguageProvider>().locale.languageCode;

    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.45)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCode,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
          isDense: true,
          borderRadius: BorderRadius.circular(16),
          style: TextStyle(
            fontSize: 12,
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
          dropdownColor: Theme.of(context).cardColor,
          selectedItemBuilder: (context) {
            return _options
                .map(
                  (option) => Text(
                    option.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                )
                .toList(growable: false);
          },
          items: _options
              .map(
                (option) => DropdownMenuItem<String>(
                  value: option.code,
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (value) {
            if (value == null) {
              return;
            }

            context.read<LanguageProvider>().changeLanguage(value);
          },
        ),
      ),
    );
  }
}
