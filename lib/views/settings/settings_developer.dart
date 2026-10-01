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
            radius: 12,
            borderColor: AppColors.rose,
            borderAlpha: 0.14,
            borderWidth: 0.6,
            shadowOpacity: 0.06,
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                // Clean header wash: a soft gold fade behind the portrait.
                // (The cropped spray corners used to sit here, but the
                // aggressive crop upscaled them into a blurry wash.)
                Container(
                  height: 148,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AppColors.goldLight.withValues(alpha: 0.55),
                        AppColors.goldLight.withValues(alpha: 0),
                      ],
                    ),
                  ),
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
                            color: AppColors.warmDark.withValues(alpha: 0.15),
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
                                  AppColors.roseLight.withValues(alpha: 0.6),
                                  AppColors.goldLight.withValues(alpha: 0.6),
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
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              letterSpacing: 0.4,
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
                      const SizedBox(height: 12),
                      _StackGroup(
                        label: lang.t('settings_stack_languages'),
                        children: const [
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
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StackGroup(
                        label: lang.t('settings_stack_frameworks'),
                        children: const [
                          _TechChip(icon: Icons.hub_outlined, label: 'React'),
                          _TechChip(icon: Icons.flutter_dash, label: 'Flutter'),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _StackGroup(
                        label: lang.t('settings_stack_tools'),
                        children: const [
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
        ],
      ),
    );
  }
}

/// One labeled stack group (languages, frameworks, tools): a small
/// section label over a left-aligned chip flow, so the stack reads as
/// tidy rows instead of one ragged cloud.
class _StackGroup extends StatelessWidget {
  final String label;
  final List<Widget> children;
  const _StackGroup({required this.label, required this.children});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.sectionLabel),
          const SizedBox(height: 8),
          Wrap(spacing: 8, runSpacing: 8, children: children),
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
        borderRadius: BorderRadius.circular(12),
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
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmDark.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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



