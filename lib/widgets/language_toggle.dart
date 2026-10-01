import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/utils/display_utils.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

/// Pill-shaped language switcher: flag + code + chevron, opens a bottom
/// sheet with the app's three languages (Tagalog, Bicol, English).
class LanguageToggle extends StatelessWidget {
  const LanguageToggle({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final flag = DisplayUtils.languageFlag(lang.language);

    return Material(
      color: Colors.white.withValues(alpha: 0.07),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.gold.withValues(alpha: 0.45),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          showModalBottomSheet(
            context: context,
            backgroundColor: AppColors.paper,
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
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    flag,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: AppColors.goldLight,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                DisplayUtils.languageCode(lang.language),
                style: TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 11,
                  color: AppColors.linen,
                  fontWeight: lang.isBicol ? FontWeight.w400 : FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 2),
              const Icon(Icons.expand_more, size: 14, color: AppColors.linen),
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

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Drag handle — the standard modern bottom-sheet affordance.
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.warmDark.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            lang.t('settings_language'),
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 16),
          _LangOption(
            flag: 'PH',
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
            flag: 'UK',
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
    final isPlainCode = DisplayUtils.isPlainText(flag);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.roseLight : AppColors.cream,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.rose
                : AppColors.stoneBorder.withValues(alpha: 0.7),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Text(
              flag,
              style: TextStyle(
                fontFamily: 'Lora',
                fontSize: isPlainCode ? 15 : 24,
                letterSpacing: isPlainCode ? 0.5 : 0,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Lora',
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
