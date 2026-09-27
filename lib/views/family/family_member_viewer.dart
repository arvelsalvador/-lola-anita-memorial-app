part of 'family_page.dart';

/// Opens the member's display picture full-screen with pinch-to-zoom.
/// Pushed above the member detail sheet, so closing it returns to the
/// sheet. No-op when the member has no photo.
void showMemberPhotoViewer(BuildContext context, FamilyMember member) {
  if (member.photoPath == null) return;
  Navigator.of(context).push(
    PageRouteBuilder(
      opaque: false,
      barrierColor: AppColors.viewerBackground.withValues(alpha: 0.94),
      barrierDismissible: true,
      transitionDuration: const Duration(milliseconds: 220),
      reverseTransitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (context, animation, secondaryAnimation) {
        return FadeTransition(
          opacity: animation,
          child: _MemberPhotoViewer(member: member),
        );
      },
    ),
  );
}

/// Full-screen viewer for one member's display picture: pinch-to-zoom
/// via [InteractiveViewer], member name caption, close button. A quick
/// tap anywhere dismisses; an active drag/pinch gesture wins over the
/// tap recognizer so zooming and panning still work.
class _MemberPhotoViewer extends StatelessWidget {
  final FamilyMember member;

  const _MemberPhotoViewer({required this.member});

  @override
  Widget build(BuildContext context) {
    final photoPath = member.photoPath;
    if (photoPath == null) return const SizedBox.shrink();
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Stack(
          fit: StackFit.expand,
          children: [
            InteractiveViewer(
              minScale: 0.8,
              maxScale: 4.0,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).pop(),
                // Tight bounds so BoxFit.contain scales small sources
                // (e.g. low-res portraits) UP to fill the screen instead
                // of rendering them at intrinsic pixel size.
                child: SizedBox.expand(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Image.asset(
                      photoPath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      // Full-screen viewer: bounded to the longest screen
                      // edge (covers both orientations) instead of native
                      // camera resolution.
                      cacheWidth: ImageDecode.width(
                        MediaQuery.sizeOf(context).longestSide,
                        context,
                      ),
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.broken_image,
                        size: 80,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton(
                // App-locale close label (not the system locale) so the
                // tooltip follows the in-app EN/TL/BC toggle.
                tooltip: context.read<LanguageProvider>().t(
                  'family_sheet_close',
                ),
                icon: const Icon(
                  Icons.close_rounded,
                  color: Colors.white,
                  size: 28,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            Positioned(
              left: 24,
              right: 24,
              bottom: 24,
              child: Text(
                member.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens the shared member-detail bottom sheet for [member]. This is THE
/// popup for every relative card — Mga Anak, Mga Kapatid, Mga Apo and any
/// future section all funnel through here; only the tapped person's data
/// differs. Dismisses via swipe-down, tapping the barrier, or the X button.
void showMemberDetailSheet(BuildContext context, FamilyMember member) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _MemberDetailSheet(member: member),
  );
}

/// Reusable "full info" popup for one family member: large portrait, name,
/// relation, years/age chip, status + tagline, photo count, bio, quote,
/// and tag chips. Every block beyond name/role renders only when the model
/// has data for it, so photo-less grandchildren get a compact sheet while
/// siblings with bios get the full layout. Content scrolls when it exceeds
/// the sheet's max height (80% of the screen).
class _MemberDetailSheet extends StatelessWidget {
  final FamilyMember member;

  const _MemberDetailSheet({required this.member});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Birth–death years when present (root-style members), otherwise the
    // localized age string for grandchildren.
    String? ageText;
    if (member.yearsLabel != null) {
      ageText = member.yearsLabel;
    } else if (member.ageYears != null) {
      ageText = lang.t('family_age_years', {'count': '${member.ageYears}'});
    } else if (member.ageMonths != null) {
      ageText = lang.t('family_age_months', {'count': '${member.ageMonths}'});
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle + close button share the top band ────────
            SizedBox(
              height: 44,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.muted.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    right: 6,
                    child: IconButton(
                      tooltip: lang.t('family_sheet_close'),
                      icon: const Icon(Icons.close, size: 20),
                      color: AppColors.warmMid,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),

            // ── Large portrait (taps open the full-screen viewer) ───
            Center(
              child: _MemberPortrait(
                member: member,
                size: 120,
                ringWidth: 1.6,
                initialsFontSize: 30,
                familyBorder: true,
                onPhotoTap: () => showMemberPhotoViewer(context, member),
              ),
            ),
            const SizedBox(height: 14),

            // ── Name + relation ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                member.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'PlayfairDisplay',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textDark,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              lang.t(member.roleKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontStyle: FontStyle.italic,
                fontSize: 13,
                color: AppColors.warmMid,
              ),
            ),

            // ── Years / age chip ────────────────────────────────────
            if (ageText != null) ...[
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldLight.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    ageText,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.warmDeep,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ],

            // ── Status dot + tagline (root-style members) ───────────
            if (member.statusLabel != null ||
                (member.tagline)?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (member.statusLabel != null) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      member.statusLabel!,
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.warmDeep,
                      ),
                    ),
                  ],
                ],
              ),
              if ((member.tagline)?.isNotEmpty == true) ...[
                const SizedBox(height: 3),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    member.tagline!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontStyle: FontStyle.italic,
                      fontSize: 11.5,
                      color: AppColors.warmMid,
                    ),
                  ),
                ),
              ],
            ],

            // ── Shared-photos count ─────────────────────────────────
            if (member.photoCount != null) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.photo_library_outlined,
                    size: 13,
                    color: AppColors.gold,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${member.photoCount} ${lang.t('family_photos_with')}',
                    style: const TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                ],
              ),
            ],

            // ── Full story (falls back to the short bio) ──────────
            if (member.storyKey != null || member.bioKey != null) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('family_sheet_full_story').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Oversized opening quote mark hugging the text.
                        Text(
                          '\u201C',
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 44,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: AppColors.gold.withValues(alpha: 0.45),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            member.storyKey != null
                                ? lang.t(member.storyKey!)
                                : lang.t(member.bioKey!),
                            textAlign: TextAlign.justify,
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontSize: 12.5,
                              height: 1.7,
                              color: AppColors.warmDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ── Identity ──────────────────────────────────────────
            if (member.roleKey.isNotEmpty ||
                member.birthplace != null ||
                member.occupation != null ||
                member.activeSince != null) ...[
              const SizedBox(height: 18),
              const OrnamentDivider(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('family_sheet_identity').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SheetRow(
                      icon: Icons.person_outline_rounded,
                      label: lang.t('family_sheet_role'),
                      value: lang.t(member.roleKey),
                    ),
                    if (member.birthplace != null)
                      _SheetRow(
                        icon: Icons.place_outlined,
                        label: lang.t('family_sheet_birthplace'),
                        value: member.birthplace!,
                      ),
                    if (member.occupation != null)
                      _SheetRow(
                        icon: Icons.work_outline_rounded,
                        label: lang.t('family_sheet_occupation'),
                        value: member.occupation!,
                      ),
                    if (member.activeSince != null)
                      _SheetRow(
                        icon: Icons.calendar_today_outlined,
                        label: lang.t('family_sheet_active_since'),
                        value: member.activeSince!,
                      ),
                    if (member.nickname != null)
                      _SheetRow(
                        icon: Icons.badge_outlined,
                        label: lang.t('family_sheet_nickname'),
                        value: member.nickname!,
                      ),
                  ],
                ),
              ),
            ],

            // ── Family ────────────────────────────────────────────
            if (member.spouseName != null ||
                member.childrenCount != null ||
                member.grandchildrenCount != null) ...[
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lang.t('family_sheet_family').toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'PlayfairDisplay',
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.gold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _SheetRow(
                      icon: Icons.favorite_outline_rounded,
                      label: lang.t('family_sheet_spouse'),
                      value:
                          member.spouseName ??
                          lang.t('family_sheet_not_recorded'),
                    ),
                    if (member.childrenCount != null)
                      _SheetRow(
                        icon: Icons.family_restroom_rounded,
                        label: lang.t('family_sheet_children'),
                        value: lang.t('family_sheet_children_count', {
                          'count': '${member.childrenCount}',
                        }),
                      ),
                    if (member.grandchildrenCount != null)
                      _SheetRow(
                        icon: Icons.escalator_warning_rounded,
                        label: lang.t('family_sheet_grandchildren'),
                        value: lang.t('family_sheet_grandchildren_count', {
                          'count': '${member.grandchildrenCount}',
                        }),
                      ),
                  ],
                ),
              ),
            ],

            // ── Quote ───────────────────────────────────────────────
            if ((member.quoteKey)?.isNotEmpty == true) ...[
              const SizedBox(height: 16),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 28),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.25),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  '"${lang.t(member.quoteKey!)}"',
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontStyle: FontStyle.italic,
                    fontSize: 12.5,
                    height: 1.5,
                    color: AppColors.warmDeep,
                  ),
                ),
              ),
            ],

            // ── Tag chips ───────────────────────────────────────────
            if (member.tags.isNotEmpty) ...[
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [for (final tag in member.tags) TagChip(label: tag)],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// One label/value row in the member sheet's Identity and Family
/// sections: small gold-outlined icon circle, label, and a right-aligned
/// muted value with a hairline divider underneath — matching the
/// member-sheet design mock.
class _SheetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _SheetRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.muted.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.45),
                width: 1,
              ),
            ),
            child: Icon(icon, size: 13, color: AppColors.warmMid),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 11.5,
                color: AppColors.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

