part of '../family_page.dart';

/// The featured "root" family member card (Anita in the screenshot):
/// a shrink-wrapped, centered memorial plaque — keepsake-framed photo on
/// top, then name, italic role, and a gold letter-spaced years/meta row.
class FamilyRootCard extends StatelessWidget {
  final FamilyMember member;

  const FamilyRootCard({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Shrink-wrapped and centered: the plaque hugs its content instead of
    // stretching edge-to-edge (capped so very long translated names can't
    // push it past a phone screen).
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: OrnamentalCard(
          radius: 20,
          borderColor: AppColors.gold,
          borderAlpha: 0.2,
          borderWidth: 1,
          shadowOpacity: 0.06,
          shadowBlur: 16,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MemberPortrait(
                    member: member,
                    size: 96,
                    ringAlpha: 0.45,
                    ringWidth: 1.6,
                    badgeSize: 22,
                    badgeIconSize: 11,
                    badgeBorderWidth: 2,
                    badgeOffset: const Offset(-2, -2),
                    initialsFontSize: 24,
                  ),
                  const SizedBox(width: 14),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          member.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                lang.t(member.roleKey),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'PlayfairDisplay',
                                  fontStyle: FontStyle.italic,
                                  fontSize: 12,
                                  color: AppColors.rose,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
                              Icons.favorite_rounded,
                              size: 9,
                              color: AppColors.rose,
                            ),
                          ],
                        ),
                        if (member.statusLabel != null ||
                            member.tagline != null) ...[
                          const SizedBox(height: 8),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 6,
                            children: [
                              if (member.statusLabel != null)
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.gold,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      member.statusLabel!,
                                      style: const TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.warmMid,
                                      ),
                                    ),
                                  ],
                                ),
                              if (member.statusLabel != null &&
                                  member.tagline != null)
                                const Text(
                                  '·',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                              if (member.tagline != null)
                                Text(
                                  member.tagline!,
                                  style: const TextStyle(
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                        if (member.yearsLabel != null ||
                            member.photoCount != null) ...[
                          const SizedBox(height: 10),
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              if (member.yearsLabel != null)
                                Text(
                                  member.yearsLabel!,
                                  style: const TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontSize: 10,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.gold,
                                  ),
                                ),
                              if (member.yearsLabel != null &&
                                  member.photoCount != null)
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 6),
                                  child: Text(
                                    '·',
                                    style: TextStyle(
                                      fontFamily: 'PlayfairDisplay',
                                      fontSize: 10,
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ),
                              if (member.photoCount != null)
                                Text(
                                  '${member.photoCount} ${_familyText(lang, 'family_photos_with', 'larawan kasama')}',
                                  style: const TextStyle(
                                    fontFamily: 'PlayfairDisplay',
                                    fontStyle: FontStyle.italic,
                                    fontSize: 10.5,
                                    color: AppColors.muted,
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether a group should be rendered with the grandchildren layout
/// (circular avatars + age labels).
bool _isApoGroup(FamilyGroup group) =>
    group.members.isNotEmpty &&
    group.members.any((m) => m.ageYears != null || m.ageMonths != null);

/// Whether a group renders the straight per-column descent design (the
/// "Mga Apo" look): vertically via FamilyApoSection (the pager) when the
/// data has ages (see [_isApoGroup]); otherwise the generic grid draws
/// its own straight lines through the header. FamilyPage also uses this
/// to skip the generic single-spine connector right before the section,
/// since the section draws its own per-column continuation.
bool _isStraightDescentGroup(FamilyGroup group) =>
    group.labelKey == 'family_group_grandchildren';
