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

  const AppBrandBar({super.key, this.greeting, this.onSettingsTap});

  @override
  Widget build(BuildContext context) {
    final hasGreeting = greeting != null && greeting!.isNotEmpty;
    return Container(
      color: AppColors.charcoal,
      child: SafeArea(
        bottom: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
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
                                            fontFamily: 'Lora',
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
                                            fontFamily: 'Lora',
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
                                      fontFamily: 'Lora',
                                      fontFamilyFallback: [
                                        'Times New Roman',
                                        'serif',
                                      ],
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
