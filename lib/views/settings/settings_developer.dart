part of 'settings_page.dart';

/// About the Developer: portfolio card — sprig-dressed header with the
/// profile photo, name, role between rules, dedication, icon chips,
/// a full-width button into the Family page, and two mini cards
/// (Projects, For Nanay) below.
class _AboutDeveloperPage extends StatelessWidget {
  const _AboutDeveloperPage({this.onViewFamily});

  /// Opens the Family tab in the bottom nav (provided by Home).
  final VoidCallback? onViewFamily;

  static const _photo = 'assets/images/Family DP/arvel.jpg';
  static const _spray = 'assets/images/Editing images/Memories_design_trim.png';

  /// Closes Settings entirely, then jumps to the real Family tab —
  /// not a separate page.
  void _openFamily(BuildContext context) {
    Navigator.of(context).popUntil((route) => route.isFirst);
    onViewFamily?.call();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DetailScaffold(
      title: lang.t('settings_about_dev_title'),
      child: Column(
        children: [
          OrnamentalCard(
            radius: 16,
            borderColor: AppColors.rose,
            borderAlpha: 0.14,
            borderWidth: 0.6,
            shadowOpacity: 0.06,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Cream header dressed with leafy sprigs (cropped ends
                // of the memorial spray asset) at both top corners,
                // portrait centered between them.
                SizedBox(
                  height: 140,
                  child: Stack(
                    children: [
                      Positioned(
                        left: -28,
                        top: 0,
                        child: Image.asset(
                          _spray,
                          width: 150,
                          height: 96,
                          fit: BoxFit.cover,
                          cacheWidth: ImageDecode.width(150, context),
                          alignment: Alignment.centerLeft,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        right: -28,
                        top: 0,
                        child: Image.asset(
                          _spray,
                          width: 150,
                          height: 96,
                          fit: BoxFit.cover,
                          cacheWidth: ImageDecode.width(150, context),
                          alignment: Alignment.centerRight,
                          errorBuilder: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.gold.withValues(alpha: 0.5),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.warmDark.withValues(
                                    alpha: 0.15,
                                  ),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                _photo,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                cacheWidth: ImageDecode.width(96, context),
                                errorBuilder: (_, _, _) => Container(
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppColors.roseLight.withValues(
                                          alpha: 0.6,
                                        ),
                                        AppColors.goldLight.withValues(
                                          alpha: 0.6,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: const Text(
                                    'AS',
                                    style: TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 28,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.roseDeep,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: Column(
                    children: [
                      const Text(
                        'Arvel Salvador',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          fontFamily: 'Lora',
                          fontFamilyFallback: ['Times New Roman', 'serif'],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang.t('settings_about_dev_role'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: AppColors.goldInk,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.gold.withValues(alpha: 0.35),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.t('settings_about_dev_dedication'),
                        textAlign: TextAlign.justify,
                        style: AppTextStyles.bodyText,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.rose.withValues(alpha: 0.25),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang
                                .t('settings_about_dev_built_with')
                                .toUpperCase(),
                            style: AppTextStyles.sectionLabel,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.rose.withValues(alpha: 0.25),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      const Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          _TechChip(icon: Icons.web_rounded, label: 'HTML'),
                          _TechChip(icon: Icons.palette_outlined, label: 'CSS'),
                          _TechChip(
                            icon: Icons.javascript_rounded,
                            label: 'JavaScript',
                          ),
                          _TechChip(icon: Icons.dns_outlined, label: 'PHP'),
                          _TechChip(
                            icon: Icons.terminal_rounded,
                            label: 'Python',
                          ),
                          _TechChip(
                            icon: Icons.window_outlined,
                            label: 'VB.NET',
                          ),
                          _TechChip(icon: Icons.code_rounded, label: 'Dart'),
                          _TechChip(icon: Icons.hub_outlined, label: 'React'),
                          _TechChip(icon: Icons.flutter_dash, label: 'Flutter'),
                          _TechChip(
                            icon: Icons.local_fire_department_rounded,
                            label: 'Firebase',
                          ),
                          _TechChip(
                            icon: Icons.source_outlined,
                            label: 'GitHub',
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      _FamilyButton(
                        label: lang.t('settings_about_dev_view_family'),
                        onTap: () => _openFamily(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _DevMiniCard(
                    icon: Icons.folder_outlined,
                    iconBackground: AppColors.iconBgOlive,
                    title: lang.t('settings_dev_projects_title'),
                    body: lang.t('settings_dev_projects_body'),
                    onTap: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const _ProjectsPage())),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DevMiniCard(
                    icon: Icons.favorite_outline_rounded,
                    iconBackground: AppColors.devCopper,
                    title: lang.t('settings_dev_for_nanay_title'),
                    body: lang.t('settings_dev_for_nanay_body'),
                    onTap: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
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

/// Pill chip with a small icon, used for the developer's stack.
/// Labels name only stack this memorial verifiably uses (pubspec).
class _TechChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _TechChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.25),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.warmDeep),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.warmDeep,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width brown gradient button opening the Family page.
class _FamilyButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FamilyButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [AppColors.devCopper, AppColors.devCopperDeep],
            ),
            borderRadius: BorderRadius.circular(99),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmDark.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(99),
            onTap: onTap,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.people_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  Icons.arrow_forward_rounded,
                  size: 20,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small tappable card under the portfolio: icon, title, blurb, arrow,
/// and a sprig tucked in the bottom corner.
class _DevMiniCard extends StatelessWidget {
  final IconData icon;
  final Color iconBackground;
  final String title;
  final String body;
  final VoidCallback onTap;
  const _DevMiniCard({
    required this.icon,
    required this.iconBackground,
    required this.title,
    required this.body,
    required this.onTap,
  });

  static const _spray = 'assets/images/Editing images/Memories_design_trim.png';

  @override
  Widget build(BuildContext context) {
    return OrnamentalCard(
      radius: 14,
      borderColor: AppColors.gold,
      borderAlpha: 0.18,
      borderWidth: 0.6,
      shadowOpacity: 0.06,
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -18,
                bottom: -8,
                child: Image.asset(
                  _spray,
                  width: 84,
                  height: 48,
                  fit: BoxFit.cover,
                  cacheWidth: ImageDecode.width(84, context),
                  alignment: Alignment.centerRight,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 48, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: iconBackground,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(icon, size: 20, color: Colors.white),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        fontFamily: 'Lora',
                        fontFamilyFallback: ['Times New Roman', 'serif'],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Expanded(
                      child: Text(
                        body,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 22,
                      color: AppColors.rose,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

