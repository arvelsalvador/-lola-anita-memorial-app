import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/controllers/display_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

/// Pill-shaped language switcher: flag + code + chevron, opens a bottom
/// sheet with the app's three languages (Tagalog, Bicol, English).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final flag = DisplayController.languageFlag(lang.language);

    return Material(
      color: Colors.white.withValues(alpha: 0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.65),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.white,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (context) => const _LanguageSheet(),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!lang.isBicol) ...[
                Text(flag, style: const TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
              ],
              Text(
                DisplayController.languageCode(lang.language),
                style: TextStyle(
                  fontSize: 11,
                  color: const Color(0xFFFAF0E6),
                  fontWeight: lang.isBicol ? FontWeight.w400 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 14, color: Color(0xFFFAF0E6)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageSheet extends StatelessWidget {
  const _LanguageSheet();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lang.t('settings_language'),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _LangOption(
            flag: '🇵🇭',
            label: 'Tagalog',
            selected: lang.isTagalog,
            onTap: () {
              lang.setLanguage(AppLanguage.tagalog);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _LangOption(
            flag: 'BC',
            label: 'Bicol',
            selected: lang.isBicol,
            onTap: () {
              lang.setLanguage(AppLanguage.bicol);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
          _LangOption(
            flag: '🇬🇧',
            label: 'English',
            selected: lang.isEnglish,
            onTap: () {
              lang.setLanguage(AppLanguage.english);
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _LangOption extends StatelessWidget {
  final String flag;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangOption({
    required this.flag,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPlainCode = DisplayController.isPlainText(flag);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseLight : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.rose : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(
                fontSize: isPlainCode ? 15 : 24,
                letterSpacing: isPlainCode ? 0.5 : 0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: AppColors.textDark,
              ),
            ),
            const Spacer(),
            if (selected)
              const Icon(Icons.check_circle, color: AppColors.rose, size: 20),
          ],
        ),
      ),
    );
  }
}
