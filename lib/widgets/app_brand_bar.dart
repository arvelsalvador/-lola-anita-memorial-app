import 'package:flutter/material.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/widgets/language_toggle.dart';

/// Shared slim brand bar: leaf mark + "nanay anita" on the left,
/// language toggle (+ optional settings) on the right, with a soft
/// fading gold seam underneath.
///
/// - Splash uses `const AppBrandBar()` — brand + language only, no
///   settings gear, no visitor greeting.
/// - Home passes `greeting` (Hello/Kumusta + first name) and
///   `onSettingsTap` to get the full bar.
class AppBrandBar extends StatelessWidget {
  final String? greeting;
  final VoidCallback? onSettingsTap;

  /// Optional help entry (the first-run guide). Omitted on the splash, where
  /// there is no app to explain yet.
  final VoidCallback? onHelpTap;
  final String? helpTooltip;

  /// Optional tap handler for the brand group (leaf + title + greeting) on the left.
  /// When provided, tapping navigates to the home tab.
  final VoidCallback? onHomeTap;
  final String? homeTooltip;

  /// Optional fill override. The Pakikiramay tab passes a translucent warm
  /// brown so the fixed gradient shows through; everything else keeps the
  /// default charcoal.
  final Color? backgroundColor;

  const AppBrandBar({
    super.key,
    this.greeting,
    this.onSettingsTap,
    this.onHelpTap,
    this.helpTooltip,
    this.onHomeTap,
    this.homeTooltip,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasGreeting = greeting != null && greeting!.isNotEmpty;
    final brandGroup = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.gold.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.35),
              width: 0.8,
            ),
          ),
          child: const Icon(
            Icons.eco,
            size: 16,
            color: AppColors.goldLight,
          ),
        ),
        const SizedBox(width: 9),
        Flexible(
          child: hasGreeting
              ? Semantics(
                  header: true,
                  label: greeting,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'nanay anita',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.6,
                          color: AppColors.gold,
                          fontFamily: 'Inter',
                          fontFamilyFallback: [
                            'Times New Roman',
                            'serif',
                          ],
                        ),
                      ),
                      Text(
                        greeting!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: AppColors.goldLight,
                          fontFamily: 'Inter',
                          fontFamilyFallback: [
                            'Times New Roman',
                            'serif',
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              : const Text(
                  'nanay anita',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.4,
                    color: AppColors.goldLight,
                    fontFamily: 'Inter',
                    fontFamilyFallback: [
                      'Times New Roman',
                      'serif',
                    ],
                  ),
                ),
        ),
      ],
    );

    return Container(
      color: backgroundColor ?? AppColors.charcoal,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  onHomeTap != null ? 6 : 12,
                  0,
                  12,
                  0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: onHomeTap != null
                          ? Semantics(
                              button: true,
                              label: homeTooltip ?? 'Pumunta sa Tahanan',
                              child: Tooltip(
                                message: homeTooltip ?? 'Pumunta sa Tahanan',
                                child: Material(
                                  color: Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  clipBehavior: Clip.antiAlias,
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    mouseCursor: SystemMouseCursors.click,
                                    onTap: onHomeTap,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      child: brandGroup,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : brandGroup,
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (onHelpTap != null) ...[
                          Tooltip(
                            message: helpTooltip ?? '',
                            child: Material(
                              color: Colors.transparent,
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: onHelpTap,
                                child: const SizedBox(
                                  width: 40,
                                  height: 40,
                                  child: Icon(
                                    Icons.help_outline_rounded,
                                    size: 20,
                                    color: AppColors.goldLight,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 2),
                        ],
                        const LanguageToggle(),
                        if (onSettingsTap != null) ...[
                          const SizedBox(width: 6),
                          Material(
                            color: Colors.transparent,
                            shape: const CircleBorder(),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              customBorder: const CircleBorder(),
                              onTap: onSettingsTap,
                              child: const SizedBox(
                                width: 40,
                                height: 40,
                                child: Icon(
                                  Icons.settings_outlined,
                                  size: 20,
                                  color: AppColors.goldLight,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.gold.withValues(alpha: 0),
                    AppColors.gold.withValues(alpha: 0.55),
                    AppColors.gold.withValues(alpha: 0),
                  ],
                  stops: const [0.08, 0.5, 0.92],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
