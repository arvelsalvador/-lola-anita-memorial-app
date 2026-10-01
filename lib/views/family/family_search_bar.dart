part of 'family_page.dart';

/// Slim pill-shaped search field over the whole pamilyang Lumbao — the
/// "Lahat / Direktang pamilya / Mga Apo" filter pills keep scrolling the
/// page, while this field live-filters members by name (and spouse name)
/// across every group, root included. Results render as tappable tiles
/// that open the same detail sheet as the member cards.
class FamilySearchBar extends StatefulWidget {
  const FamilySearchBar({super.key});

  @override
  State<FamilySearchBar> createState() => _FamilySearchBarState();
}

class _FamilySearchBarState extends State<FamilySearchBar> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  /// Every person reachable from the family data: each group's members,
  /// plus spouses (shown as "+ Name" on tree cards) and the root.
  List<FamilyMember> _allPeople(FamilyModel data) {
    final people = <FamilyMember>[data.rootMember];
    final seen = <String>{data.rootMember.name};
    for (final group in data.groups) {
      for (final member in group.members) {
        if (seen.add(member.name)) people.add(member);
      }
      for (final member in group.members) {
        final spouse = member.spouseName;
        if (spouse != null && seen.add(spouse)) {
          people.add(
            FamilyMember(
              name: spouse,
              roleKey: member.roleKey,
              spouseOf: member.name,
            ),
          );
        }
      }
    }
    return people;
  }

  List<FamilyMember> _matches(String query, FamilyModel data) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _allPeople(data)
        .where(
          (m) =>
              m.name.toLowerCase().contains(q) ||
              (m.spouseOf ?? '').toLowerCase().contains(q),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    const data = FamilyController.data;
    final results = _matches(_query, data);

    return Column(
      children: [
        OrnamentalCard(
          height: 48,
          radius: 12,
          borderColor: AppColors.gold,
          borderAlpha: 0.16,
          borderWidth: 0.8,
          shadowOpacity: 0.02,
          shadowBlur: 8,
          shadowOffset: const Offset(0, 2),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(
                Icons.search,
                size: 19,
                color: AppColors.warmMid.withValues(alpha: 0.8),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  onChanged: (value) => setState(() => _query = value),
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 13.5,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration.collapsed(
                    hintText: lang.t('family_search_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13.5,
                      color: AppColors.muted,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 9),
              if (_query.isEmpty)
                Icon(
                  Icons.tune,
                  size: 19,
                  color: AppColors.warmMid.withValues(alpha: 0.8),
                )
              else
                InkWell(
                  onTap: () {
                    _controller.clear();
                    _focus.unfocus();
                    setState(() => _query = '');
                  },
                  customBorder: const CircleBorder(),
                  child: const Icon(
                    Icons.close,
                    size: 19,
                    color: AppColors.warmMid,
                  ),
                ),
            ],
          ),
        ),
        // Results panel — appears under the field while a query is active.
        if (_query.trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          OrnamentalCard(
            radius: 12,
            borderColor: AppColors.gold,
            borderAlpha: 0.14,
            borderWidth: 0.8,
            shadowOpacity: 0.03,
            shadowBlur: 10,
            shadowOffset: const Offset(0, 3),
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: results.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Text(
                        lang.t('family_search_empty'),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            lang.t('family_search_results', {
                              'count': '${results.length}',
                            }),
                            style: const TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 11,
                              letterSpacing: 0.6,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                      ),
                      for (final member in results)
                        _SearchResultTile(member: member),
                    ],
                  ),
          ),
        ],
      ],
    );
  }
}

/// One row in the family search results: avatar, name, and the localized
/// relation label. Tapping opens the shared member detail sheet.
class _SearchResultTile extends StatelessWidget {
  final FamilyMember member;

  const _SearchResultTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final initials = DisplayUtils.initialsOf(member.name);
    final colorIndex = member.name.hashCode.abs();
    final bg = _apoAvatarBg[colorIndex % _apoAvatarBg.length];
    final fg = _apoAvatarText[colorIndex % _apoAvatarText.length];

    return InkWell(
      onTap: () => showMemberDetailSheet(context, member),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: member.photoPath == null ? bg : Colors.white,
              ),
              child: member.photoPath == null
                  ? Center(
                      child: Text(
                        initials,
                        style: TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        member.photoPath!,
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        cacheWidth: ImageDecode.width(38, context),
                        errorBuilder: (_, _, _) => Center(
                          child: Text(
                            initials,
                            style: TextStyle(
                              fontFamily: 'Lora',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: fg,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'Lora',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

