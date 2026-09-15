part of '../home_page.dart';

/// Slim fixed top bar: leaf logo + "nanay anita" on the left, language
/// toggle on the right, with a thin gold divider underneath. Stays at the
/// top while the hero section scrolls away.
class _TopBar extends StatelessWidget {
  /// Jumps straight to the Family tab in the bottom nav. Handed to
  /// Settings so "Tingnan sa Pamilya" lands on the real tab.
  final VoidCallback onOpenFamily;

  /// Jumps to any tab in the bottom nav. Handed to Settings so the
  /// About-Us rows land on their real tabs.
  final ValueChanged<int> onOpenTab;

  const _TopBar({required this.onOpenFamily, required this.onOpenTab});

  @override
  Widget build(BuildContext context) {
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
                // Tight margins pin the brand to the very left edge
                // and the toggle + gear to the very right edge.
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.eco, size: 22, color: AppColors.goldLight),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'nanay anita',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: AppColors.goldLight,
                                fontFamily: 'Georgia',
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
                        const SizedBox(width: 4),
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          visualDensity: VisualDensity.compact,
                          icon: const Icon(
                            Icons.settings_outlined,
                            size: 20,
                            color: AppColors.goldLight,
                          ),
                          onPressed: () {
                            Navigator.of(context).push(
                              fadeRoute(
                                SettingsPage(
                                  onViewFamily: onOpenFamily,
                                  onOpenTab: onOpenTab,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            // Thin gold divider between the brand bar and the hero.
            Container(height: 1, color: AppColors.gold.withValues(alpha: 0.55)),
          ],
        ),
      ),
    );
  }
}
