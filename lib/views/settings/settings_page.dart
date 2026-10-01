import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/widgets/ornamental_card.dart';

part 'settings_about.dart';
part 'settings_developer.dart';

/// One row in the settings menu.
class _SettingEntry {
  final IconData icon;
  final Color iconColor;
  final String titleKey;
  final String descKey;
  final WidgetBuilder page;
  const _SettingEntry({
    required this.icon,
    required this.iconColor,
    required this.titleKey,
    required this.descKey,
    required this.page,
  });
}

/// Menu rows. Built by a function (not a top-level const) because the
/// developer row carries the Home shell's "open Family tab" callback
/// and the About-Us rows carry the general tab opener.
List<_SettingEntry> _entriesFor(
  VoidCallback? onViewFamily,
  ValueChanged<int>? onOpenTab,
) => [
  _SettingEntry(
    icon: Icons.person_outline_rounded,
    iconColor: AppColors.gold,
    titleKey: 'settings_about_dev_title',
    descKey: 'settings_desc_dev',
    page: (_) => _AboutDeveloperPage(onViewFamily: onViewFamily),
  ),
  _SettingEntry(
    icon: Icons.info_outline_rounded,
    iconColor: AppColors.rose,
    titleKey: 'settings_about_app_title',
    descKey: 'settings_desc_about',
    page: (_) => _AboutUsPage(onOpenTab: onOpenTab),
  ),
];

/// Settings menu: leaf + personalize subtitle, pill search that
/// live-filters the rows, one section card holding a row per area
/// (each with a two-line label), and a version footer pinned low.
/// Tapping a row pushes its detail page.
class SettingsPage extends StatefulWidget {
  /// Jumps to the Family tab in the bottom nav (provided by Home).
  /// Used by "Tingnan sa Pamilya" so it lands on the real tab.
  final VoidCallback? onViewFamily;

  /// Jumps to any tab in the bottom nav (provided by Home). Used by
  /// the About-Us rows so they land on their real tabs.
  final ValueChanged<int>? onOpenTab;

  const SettingsPage({super.key, this.onViewFamily, this.onOpenTab});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _query = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final q = _query.trim().toLowerCase();
    final entries = _entriesFor(widget.onViewFamily, widget.onOpenTab);
    final visible = q.isEmpty
        ? entries
        : entries
              .where(
                (e) =>
                    lang.t(e.titleKey).toLowerCase().contains(q) ||
                    lang.t(e.descKey).toLowerCase().contains(q),
              )
              .toList();

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: _SettingsAppBar(title: lang.t('settings_title')),
      body: LayoutBuilder(
        builder: (context, viewport) => SingleChildScrollView(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                child: ConstrainedBox(
                  // Fill the viewport so the footer rests at the bottom
                  // on tall screens, scrolling naturally when crowded.
                  constraints: BoxConstraints(
                    minHeight: viewport.maxHeight - 44,
                  ),
                  child: Column(
                    children: [
                      _SearchBar(
                        controller: _searchController,
                        hint: lang.t('settings_search_hint'),
                        onChanged: (v) => setState(() => _query = v),
                        onClear: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
                      const SizedBox(height: 16),
                      if (visible.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            lang.t('settings_search_empty'),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        )
                      else
                        OrnamentalCard(
                          radius: 12,
                          borderColor: AppColors.gold,
                          borderAlpha: 0.2,
                          borderWidth: 0.6,
                          shadowOpacity: 0.06,
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  20,
                                  18,
                                  20,
                                  6,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      lang.t('settings_menu_title'),
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textDark,
                                        fontFamily: 'Lora',
                                        fontFamilyFallback: [
                                          'Times New Roman',
                                          'serif',
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: 28,
                                      height: 2,
                                      decoration: BoxDecoration(
                                        color: AppColors.gold.withValues(
                                          alpha: 0.7,
                                        ),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: visible.length,
                                separatorBuilder: (context, _) => Divider(
                                  height: 1,
                                  thickness: 1,
                                  indent: 66,
                                  endIndent: 0,
                                  color: AppColors.muted.withValues(
                                    alpha: 0.15,
                                  ),
                                ),
                                itemBuilder: (context, i) {
                                  final entry = visible[i];
                                  return ListTile(
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: entry.iconColor.withValues(
                                          alpha: 0.12,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        entry.icon,
                                        size: 20,
                                        color: entry.iconColor,
                                      ),
                                    ),
                                    title: Text(
                                      lang.t(entry.titleKey),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textDark,
                                        fontFamily: 'Lora',
                                        fontFamilyFallback: [
                                          'Times New Roman',
                                          'serif',
                                        ],
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        lang.t(entry.descKey),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 12,
                                          color: AppColors.muted,
                                          height: 1.4,
                                        ),
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.chevron_right_rounded,
                                      size: 24,
                                      color: AppColors.muted,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                    horizontalTitleGap: 14,
                                    onTap: () => Navigator.of(
                                      context,
                                    ).push(fadeRoute(entry.page(context))),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                      const SizedBox(height: 24),
                      Text(
                        'Nanay Anita · ${lang.t('settings_about_app_version')}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 11.5,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Slim dark app bar shared by the menu and detail pages: rounded
/// chevron back on the left, centered title, no trailing action.
class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _SettingsAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(48);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.charcoal,
      foregroundColor: AppColors.goldLight,
      centerTitle: true,
      toolbarHeight: 48,
      leading: IconButton(
        icon: const Icon(Icons.chevron_left_rounded, size: 28),
        onPressed: () => Navigator.of(context).maybePop(),
      ),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
          color: AppColors.goldLight,
        ),
      ),
    );
  }
}

/// Pill search input: light warm-gray fill, magnifier on the left,
/// clear button when text is present.
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  const _SearchBar({
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Lora',
          fontSize: 14,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 14,
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 20,
            color: AppColors.muted,
          ),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 18,
                    color: AppColors.muted,
                  ),
                  onPressed: onClear,
                ),
          filled: true,
          fillColor: AppColors.paper,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 0.8,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.rose, width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Detail scaffold shared by the two pages: same dark centered
/// app bar, one centered content card below.
class _DetailScaffold extends StatelessWidget {
  final String title;
  final Widget child;
  const _DetailScaffold({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: _SettingsAppBar(title: title),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Detail pages.
// ---------------------------------------------------------------------
