// Family tab — restyled to match the "Pamilya" screenshot layout:
// header -> stats card -> search bar -> filter chips -> centered root
// member -> horizontally-scrolling branch groups -> view-full-tree button
// -> footer note.
//
// IMPORTANT: this reuses your existing architecture as-is —
// FamilyController, FamilyModel/FamilyGroup/FamilyMember, LanguageProvider,
// AppColors, and your shared widgets (OrnamentalCard, GradientAvatar,
// TagChip, Dot, OrnamentDivider, DisplayUtils.initialsOf). I only used
// AppColors tokens that were already present in your original file
// (gold, rose, warmDark, warmMid, textDark, muted, roseLight, roseDeep) —
// I have not seen app_constants.dart, so I didn't invent new ones.
//
// New lang keys this file expects (add these to your LanguageProvider's
// translation maps — they didn't exist in your original file):
//   family_filter_all            e.g. "Lahat"
//   family_filter_direct         e.g. "Direktang pamilya"
//   family_filter_apo            e.g. "Mga Apo"
//   family_view_full_tree        e.g. "Tingnan ang buong family tree"
//   family_footer_note           e.g. "Ang mga miyembro ng pamilya ay
//                                       maaaring ikonekta sa mga alaala."
library;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/core/utils/display_utils.dart';
import 'package:nita/controllers/family_controller.dart';
import 'package:nita/models/family_model.dart';
import 'package:nita/widgets/gradient_avatar.dart';
import 'package:nita/widgets/ornament_divider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/tag_chip.dart';
import 'package:nita/views/family/family_tree_canvas_page.dart';

part 'family_spines.dart';
part 'family_chrome.dart';
part 'family_search_bar.dart';
part 'family_cards.dart';
part 'family_sections.dart';
part 'family_member_viewer.dart';

/// Returns a translated label when available, otherwise a readable Filipino
/// fallback. This keeps the screen usable before new locale keys are added.
String _familyText(
  LanguageProvider lang,
  String key,
  String fallback, [
  Map<String, String>? values,
]) {
  final translated = lang.t(key, values);
  return translated == key ? fallback : translated;
}

// Pastel palette used for grandchildren who don't have a photo yet.
// Each entry is {background, text} — we cycle through these by index so
// consecutive "no-photo" cards don't repeat the same color, just like
// the LD / JD / BD circles in your screenshot.
const List<Color> _apoAvatarBg = [
  AppColors.tintLavender, // lavender
  AppColors.tintMint, // mint
  AppColors.tintPink, // pink
];
const List<Color> _apoAvatarText = [
  AppColors.accentPurple, // purple
  AppColors.accentGreen, // green
  AppColors.accentPink, // rose/pink
];

/// The Family tab: header, search, root member card, and each family
/// group as a horizontally-scrolling row of member cards.
class FamilyPage extends StatelessWidget {
  final ScrollController? controller;
  const FamilyPage({super.key, this.controller});

  @override
  Widget build(BuildContext context) {
    const data = FamilyController.data;
    final groups = data.groups;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: ListView(
          controller: controller,
          // Keep every section mounted so content below the fold lays
          // out correctly even before the page has been scrolled.
          cacheExtent: 2000,
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
          children: [
            const FamilyPageHeader(),
            const SizedBox(height: 16),
            const FamilySearchBar(),
            const SizedBox(height: 18),
            FamilyRootCard(member: data.rootMember),
            // Carry the descent line from the root card's bottom edge down
            // to the first section header: the bead marks the branch
            // origin, and that header's own spine (see _SpineBehind)
            // continues the line through into the section's branch
            // connector, so root → bus → cards reads as one unbroken line.
            if (groups.isNotEmpty)
              const _FamilyGroupConnector(height: 18, bead: true),
            for (var i = 0; i < groups.length; i++) ...[
              FamilyGroupSection(group: groups[i]),
              if (i < groups.length - 1) ...[
                // The grandchildren section draws its own straight
                // per-column descent (the pager draws its own multi
                // columns) — its columns must line up with the cards
                // above it — so the generic single spine is skipped right
                // before it. Leaving it in would punch a 22px hole into
                // the straight lines coming off the cards above.
                if (!_isApoGroup(groups[i + 1]) &&
                    !_isStraightDescentGroup(groups[i + 1]))
                  const _FamilyGroupConnector()
                else
                  const SizedBox.shrink(),
              ] else
                const SizedBox(height: 18),
            ],
            const SizedBox(height: 12),
            const FamilyFooterNote(),
          ],
        ),
      ),
    );
  }
}
