part of '../settings_page.dart';

/// About Us: brand card, "why we made this", rows into the Story /
/// Gallery / Words tabs, a made-with-love card, and a thank-you.
class _AboutUsPage extends StatelessWidget {
  /// Opens a Home tab (provided by Home). Rows land on real tabs.
  final ValueChanged<int>? onOpenTab;

  const _AboutUsPage({this.onOpenTab});

  static const _spray = 'assets/images/Editing images/Memories_design_trim.png';

  void _goTab(BuildContext context, int index) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    onOpenTab?.call(index);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DetailScaffold(
      title: lang.t('settings_about_app_title'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OrnamentalCard(
            radius: 16,
            borderColor: AppColors.gold,
            borderAlpha: 0.2,
            borderWidth: 0.6,
            shadowOpacity: 0.06,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.eco, size: 22, color: AppColors.gold),
                    SizedBox(width: 8),
                    Text(
                      'nanay anita',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: AppColors.textDark,
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang.t('settings_about_app_body'),
                  style: AppTextStyles.bodyText,
                ),
                const SizedBox(height: 12),
                Text(
                  lang.t('settings_about_app_version'),
                  style: const TextStyle(fontSize: 12, color: AppColors.muted),
                ),
                const SizedBox(height: 6),
                Text(
                  lang.t('settings_about_app_credits'),
                  style: const TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: AppColors.muted,
                    height: 1.6,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset(
                _spray,
                width: 30,
                height: 46,
                fit: BoxFit.cover,
                cacheWidth: ImageDecode.width(30, context),
                alignment: Alignment.centerLeft,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.eco_outlined,
                  size: 26,
                  color: AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  lang.t('settings_about_why_title'),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                    fontFamily: 'Georgia',
                    fontFamilyFallback: ['Times New Roman', 'serif'],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lang.t('settings_about_why_body'),
            style: AppTextStyles.bodyText,
          ),
          const SizedBox(height: 20),
          OrnamentalCard(
            radius: 16,
            borderColor: AppColors.gold,
            borderAlpha: 0.2,
            borderWidth: 0.6,
            shadowOpacity: 0.06,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _AboutRow(
                  icon: Icons.menu_book_outlined,
                  iconBackground: AppColors.iconBgSand,
                  title: lang.t('settings_about_memories_title'),
                  body: lang.t('settings_about_memories_body'),
                  onTap: () => _goTab(context, 0),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 78,
                  color: AppColors.muted.withValues(alpha: 0.15),
                ),
                _AboutRow(
                  icon: Icons.image_outlined,
                  iconBackground: AppColors.iconBgSage,
                  title: lang.t('settings_about_photos_title'),
                  body: lang.t('settings_about_photos_body'),
                  onTap: () => _goTab(context, 1),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  indent: 78,
                  color: AppColors.muted.withValues(alpha: 0.15),
                ),
                _AboutRow(
                  icon: Icons.chat_bubble_outline_rounded,
                  iconBackground: AppColors.iconBgCream,
                  title: lang.t('settings_about_messages_title'),
                  body: lang.t('settings_about_messages_body'),
                  onTap: () => _goTab(context, 3),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          OrnamentalCard(
            radius: 16,
            fill: AppColors.roseLight.withValues(alpha: 0.45),
            borderColor: AppColors.rose,
            borderAlpha: 0.2,
            borderWidth: 0.6,
            shadowOpacity: 0.06,
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned(
                  right: -18,
                  bottom: -8,
                  child: Image.asset(
                    _spray,
                    width: 90,
                    height: 52,
                    fit: BoxFit.cover,
                    cacheWidth: ImageDecode.width(90, context),
                    alignment: Alignment.centerRight,
                    errorBuilder: (_, _, _) => const SizedBox.shrink(),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 64, 18),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.paper,
                          border: Border.all(
                            color: AppColors.rose.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.favorite_outline_rounded,
                          size: 22,
                          color: AppColors.roseDeep,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('settings_about_made_title'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textDark,
                                fontFamily: 'Georgia',
                                fontFamilyFallback: [
                                  'Times New Roman',
                                  'serif',
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              lang.t('settings_about_made_body'),
                              style: const TextStyle(
                                fontSize: 12.5,
                                color: AppColors.muted,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Column(
              children: [
                const Icon(Icons.eco_outlined, size: 14, color: AppColors.gold),
                const SizedBox(height: 6),
                Text(
                  lang.t('settings_about_thanks'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.muted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One tappable row inside the About-Us card: tinted icon circle,
/// title + blurb, trailing chevron.
class _AboutRow extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _AboutRow({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackground,
                ),
                child: Icon(icon, size: 22, color: AppColors.warmDeep),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontFamily: 'Georgia',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right_rounded,
                size: 24,
                color: AppColors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
