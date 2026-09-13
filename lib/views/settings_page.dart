import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/ornamental_card.dart';

// TODO: replace with the real family email address.
const String kFamilyEmail = 'family@example.com';

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
  _SettingEntry(
    icon: Icons.mail_outline_rounded,
    iconColor: AppColors.gold,
    titleKey: 'settings_contact_title',
    descKey: 'settings_desc_contact',
    page: (_) => const _ContactPage(),
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
                      const Icon(
                        Icons.eco_outlined,
                        size: 22,
                        color: AppColors.gold,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        lang.t('settings_subtitle'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.warmMid,
                          fontFamily: 'Georgia',
                          fontFamilyFallback: [
                            'Times New Roman',
                            'serif',
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.muted,
                        ),
                      ),
                    )
                  else
                    OrnamentalCard(
                      radius: 16,
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
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lang.t('settings_menu_title'),
                                  style: const TextStyle(
                                    fontSize: 17,
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
                                Container(
                                  width: 28,
                                  height: 2,
                                  decoration: BoxDecoration(
                                    color: AppColors.gold.withValues(
                                      alpha: 0.7,
                                    ),
                                    borderRadius:
                                        BorderRadius.circular(2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics:
                                const NeverScrollableScrollPhysics(),
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
                                leading: Icon(
                                  entry.icon,
                                  size: 24,
                                  color: entry.iconColor,
                                ),
                                title: Text(
                                  lang.t(entry.titleKey),
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textDark,
                                    fontFamily: 'Georgia',
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
                                contentPadding:
                                    const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 4,
                                    ),
                                horizontalTitleGap: 14,
                                onTap: () => Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: entry.page,
                                  ),
                                ),
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

/// Dark app bar shared by the menu and detail pages: stock back arrow
/// on the left, centered title, no trailing action.
class _SettingsAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  const _SettingsAppBar({required this.title});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF1C1713),
      foregroundColor: AppColors.goldLight,
      centerTitle: true,
      title: Text(
        title,
        style: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w700,
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
        style: const TextStyle(fontSize: 14, color: AppColors.textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(fontSize: 14, color: AppColors.muted),
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
          fillColor: const Color(0xFFF0ECE5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(99),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Detail scaffold shared by the three pages: same dark centered
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

/// About Us: brand card, "why we made this", rows into the Story /
/// Gallery / Words tabs, a made-with-love card, and a thank-you.
class _AboutUsPage extends StatelessWidget {
  /// Opens a Home tab (provided by Home). Rows land on real tabs.
  final ValueChanged<int>? onOpenTab;

  const _AboutUsPage({this.onOpenTab});

  static const _spray =
      'assets/images/Editing images/Memories_design_trim.png';

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
                        fontFamilyFallback: [
                          'Times New Roman',
                          'serif',
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  lang.t('settings_about_app_body'),
                  style: AppTextStyles.serifBody,
                ),
                const SizedBox(height: 12),
                Text(
                  lang.t('settings_about_app_version'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.muted,
                  ),
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
                    fontFamilyFallback: [
                      'Times New Roman',
                      'serif',
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            lang.t('settings_about_why_body'),
            style: AppTextStyles.serifBody,
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
                  iconBackground: const Color(0xFFEBCFA8),
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
                  iconBackground: const Color(0xFFB3BC9F),
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
                  iconBackground: const Color(0xFFF1E7CF),
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
                          color: AppColors.white,
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
                const Icon(
                  Icons.eco_outlined,
                  size: 14,
                  color: AppColors.gold,
                ),
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
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: iconBackground,
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: AppColors.warmDeep,
                ),
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
                        fontFamilyFallback: [
                          'Times New Roman',
                          'serif',
                        ],
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

/// About the Developer: portfolio card — sprig-dressed header with the
/// profile photo, name, role between rules, dedication, icon chips,
/// a full-width button into the Family page, and two mini cards
/// (Projects, For Nanay) below.
class _AboutDeveloperPage extends StatelessWidget {
  const _AboutDeveloperPage({this.onViewFamily});

  /// Opens the Family tab in the bottom nav (provided by Home).
  final VoidCallback? onViewFamily;

  static const _photo = 'assets/images/Family DP/arvel.jpg';
  static const _spray =
      'assets/images/Editing images/Memories_design_trim.png';

  /// Darker gold ink: full-strength gold is too light for small
  /// italic text on white.
  static const _goldInk = Color(0xFF96742A);

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
                          alignment: Alignment.centerLeft,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
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
                          alignment: Alignment.centerRight,
                          errorBuilder: (_, _, _) =>
                              const SizedBox.shrink(),
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
                                color: AppColors.gold.withValues(
                                  alpha: 0.5,
                                ),
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
                                      fontFamily: 'Georgia',
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
                          fontFamily: 'Georgia',
                          fontFamilyFallback: [
                            'Times New Roman',
                            'serif',
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.gold.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            lang.t('settings_about_dev_role'),
                            style: const TextStyle(
                              fontSize: 13,
                              fontStyle: FontStyle.italic,
                              color: _goldInk,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.gold.withValues(
                                alpha: 0.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        lang.t('settings_about_dev_dedication'),
                        textAlign: TextAlign.justify,
                        style: AppTextStyles.serifBody,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              height: 1,
                              color: AppColors.rose.withValues(
                                alpha: 0.25,
                              ),
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
                              color: AppColors.rose.withValues(
                                alpha: 0.25,
                              ),
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
                          _TechChip(
                            icon: Icons.web_rounded,
                            label: 'HTML',
                          ),
                          _TechChip(
                            icon: Icons.palette_outlined,
                            label: 'CSS',
                          ),
                          _TechChip(
                            icon: Icons.javascript_rounded,
                            label: 'JavaScript',
                          ),
                          _TechChip(
                            icon: Icons.dns_outlined,
                            label: 'PHP',
                          ),
                          _TechChip(
                            icon: Icons.terminal_rounded,
                            label: 'Python',
                          ),
                          _TechChip(
                            icon: Icons.window_outlined,
                            label: 'VB.NET',
                          ),
                          _TechChip(
                            icon: Icons.code_rounded,
                            label: 'Dart',
                          ),
                          _TechChip(
                            icon: Icons.hub_outlined,
                            label: 'React',
                          ),
                          _TechChip(
                            icon: Icons.flutter_dash,
                            label: 'Flutter',
                          ),
                          _TechChip(
                            icon:
                                Icons.local_fire_department_rounded,
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
                        label: lang.t(
                          'settings_about_dev_view_family',
                        ),
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
                    iconBackground: const Color(0xFF7C8B5F),
                    title: lang.t('settings_dev_projects_title'),
                    body: lang.t('settings_dev_projects_body'),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _ProjectsPage(),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _DevMiniCard(
                    icon: Icons.favorite_outline_rounded,
                    iconBackground: const Color(0xFFB26B45),
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
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F1E6),
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
              fontFamily: 'Georgia',
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
              colors: [Color(0xFFB26B45), Color(0xFF8E4F2E)],
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
                      fontFamily: 'Georgia',
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

  static const _spray =
      'assets/images/Editing images/Memories_design_trim.png';

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
                      child: Icon(
                        icon,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14.5,
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

/// Projects: the one portfolio entry this memorial can verify —
/// the memorial app itself.
class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DetailScaffold(
      title: lang.t('settings_dev_projects_title'),
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.gold,
        borderAlpha: 0.2,
        borderWidth: 0.6,
        shadowOpacity: 0.06,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.eco,
                  size: 22,
                  color: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang.t('app_title'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
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
            const SizedBox(height: 10),
            Text(
              lang.t('settings_dev_project_memorial_body'),
              style: AppTextStyles.serifBody,
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TechChip(icon: Icons.flutter_dash, label: 'Flutter'),
                _TechChip(icon: Icons.code_rounded, label: 'Dart'),
                _TechChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Firebase',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lang.t('settings_about_app_version'),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact Us: intro plus a name / email / message form. Sending opens
/// the mail app with everything prefilled (photo sharing stays out
/// until an upload backend exists). Falls back to copying the message
/// when no mail app exists, so the button never dies quietly.
class _ContactPage extends StatefulWidget {
  const _ContactPage();

  @override
  State<_ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<_ContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.removeListener(_onChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final signature = [
      if (name.isNotEmpty) name,
      if (email.isNotEmpty) email,
    ].join(' · ');
    final body = signature.isEmpty ? message : '$message\n\n— $signature';
    final uri = Uri(
      scheme: 'mailto',
      path: kFamilyEmail,
      queryParameters: {'subject': 'Para kay Nanay', 'body': body},
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (!mounted) return;
        messenger.showSnackBar(
          SnackBar(
            content: Text(lang.t('settings_contact_opening')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } catch (_) {
      // Fall through to the clipboard fallback below.
    }
    await Clipboard.setData(ClipboardData(text: body));
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(lang.t('settings_contact_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final canSend = _messageController.text.trim().isNotEmpty;
    return _DetailScaffold(
      title: lang.t('settings_contact_title'),
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.gold,
        borderAlpha: 0.2,
        borderWidth: 0.6,
        shadowOpacity: 0.06,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('settings_contact_intro'),
              style: AppTextStyles.serifBody,
            ),
            const SizedBox(height: 18),
            _FieldLabel(text: lang.t('settings_contact_name_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _nameController,
              hint: lang.t('settings_contact_name_hint'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _FieldLabel(text: lang.t('settings_contact_email_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _emailController,
              hint: lang.t('settings_contact_email_hint'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _FieldLabel(text: lang.t('settings_contact_message_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _messageController,
              hint: lang.t('settings_contact_message_hint'),
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Color(0xFFB26B45),
                              Color(0xFF8E4F2E),
                            ],
                          )
                        : null,
                    color: canSend ? null : AppColors.muted,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: AppColors.warmDark.withValues(
                                alpha: 0.2,
                              ),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: canSend ? _send : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lang.t('settings_contact_send_message'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.rose,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      lang.t('settings_contact_privacy'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small semibold label above a contact field.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        fontFamily: 'Georgia',
        fontFamilyFallback: ['Times New Roman', 'serif'],
      ),
    );
  }
}

/// Warm filled text field shared by the contact form.
class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _ContactField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
        filled: true,
        fillColor: const Color(0xFFFBF8F2),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rose, width: 1),
        ),
      ),
    );
  }
}
