part of '../family_page.dart';

/// Compact version of the root-member plaque for one member inside a
/// group: framed circular portrait (or initials placeholder), centered
/// name, italic role, and any tags — same design language as
/// FamilyRootCard.
class _MemberThumbnailCard extends StatelessWidget {
  final FamilyMember member;

  /// Portrait diameter override for tight grids (e.g. four grandchildren
  /// across a phone); null keeps the default 88px portrait.
  final double? portraitSize;

  const _MemberThumbnailCard({required this.member, this.portraitSize});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();

    // Whole card is the tap target (photo, name, or role) — opens the
    // shared detail sheet for this person. GestureDetector keeps the
    // card's visual design untouched.
    return GestureDetector(
      onTap: () => showMemberDetailSheet(context, member),
      child: OrnamentalCard(
        width: double.infinity,
        radius: 18,
        borderColor: AppColors.muted,
        borderAlpha: 0.16,
        borderWidth: 0.8,
        shadowOpacity: 0.03,
        shadowBlur: 10,
        shadowOffset: const Offset(0, 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _MemberPortrait(member: member, size: portraitSize ?? 88),
            const SizedBox(height: 9),
            Text(
              member.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              lang.t(member.roleKey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontStyle: FontStyle.italic,
                fontSize: 10.5,
                color: AppColors.warmMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The framed circular portrait used across the family page: gold ring,
/// white gap, clipped photo — or the initials placeholder when the member
/// has no photo yet. Sizing/ring/badge are parameterized so the root card
/// can reuse this with bolder styling instead of duplicating it.
class _MemberPortrait extends StatelessWidget {
  final FamilyMember member;
  final double size;
  final double ringAlpha;
  final double ringWidth;
  final double badgeSize;
  final double badgeIconSize;
  final double badgeBorderWidth;
  final Offset badgeOffset;
  final double initialsFontSize;

  /// Draws the decorative Family_Border artwork over the portrait (used
  /// by the member detail sheet). The artwork is a centered wreath on a
  /// transparent 1536x1024 canvas whose drawn band spans ~0.54 of the
  /// canvas width and ~0.635 of its height, so the overlay box is
  /// expanded and cover-fitted until the wreath's outer edge encircles
  /// the photo circle.
  final bool familyBorder;

  /// Opens the full-screen photo viewer when the portrait is tapped.
  /// Wired only by the member detail sheet — card thumbnails leave it
  /// null and stay non-tappable. Ignored for photo-less members, whose
  /// initials tile never opens the viewer.
  final VoidCallback? onPhotoTap;

  static const String _familyBorderAsset =
      'assets/images/Editing images/Family_Border.png';
  static const double _familyBorderOverflowFactor = 0.22;
  static const double _familyBorderPhotoScale = 0.75;
  static const double _familyBorderVerticalShift =
      -0.45; // fraction of `size`, shifts photo down

  const _MemberPortrait({
    required this.member,
    this.size = 88,
    this.ringAlpha = 0.4,
    this.ringWidth = 1.3,
    this.badgeSize = 18,
    this.badgeIconSize = 9,
    this.badgeBorderWidth = 1.5,
    this.badgeOffset = const Offset(-1, -1),
    this.initialsFontSize = 22,
    this.familyBorder = false,
    this.onPhotoTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final initials = DisplayUtils.initialsOf(member.name);

    // Family border mode uses a slightly larger photo circle and a tighter
    // overlay expansion so the portrait sits more naturally in the wreath.
    final double photoSize = familyBorder
        ? size * _familyBorderPhotoScale
        : size;

    final Widget photoCircle = Container(
      width: photoSize,
      height: photoSize,
      padding: EdgeInsets.all(familyBorder ? 1.6 : 3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: ringAlpha),
          width: ringWidth,
        ),
      ),
      child: ClipOval(
        child: member.photoPath == null
            ? _InitialsTile(initials: initials, fontSize: initialsFontSize)
            : Image.asset(
                member.photoPath!,
                fit: BoxFit.cover,
                cacheWidth: ImageDecode.width(photoSize, context),
                errorBuilder: (context, error, stackTrace) => _InitialsTile(
                  initials: initials,
                  fontSize: initialsFontSize,
                ),
              ),
      ),
    );

    // Tapping the portrait opens the full-screen viewer (sheet only —
    // card thumbnails pass no callback). Photo-less members render the
    // initials tile and stay non-tappable.
    final bool tappable = onPhotoTap != null && member.photoPath != null;
    final String viewPhotoLabel = _familyText(
      lang,
      'family_sheet_view_photo',
      'View full photo',
    );
    final Widget portraitCircle = tappable
        ? Semantics(
            button: true,
            image: true,
            label: viewPhotoLabel,
            child: Tooltip(
              message: viewPhotoLabel,
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(onTap: onPhotoTap, child: photoCircle),
              ),
            ),
          )
        : photoCircle;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (familyBorder)
            Align(
              alignment: const Alignment(0, _familyBorderVerticalShift),
              child: portraitCircle,
            )
          else
            portraitCircle,
          if (familyBorder)
            Positioned(
              left: -size * _familyBorderOverflowFactor,
              top: -size * _familyBorderOverflowFactor,
              right: -size * _familyBorderOverflowFactor,
              bottom: -size * _familyBorderOverflowFactor,
              child: IgnorePointer(
                child: Image.asset(
                  _familyBorderAsset,
                  fit: BoxFit.cover,
                  cacheWidth: ImageDecode.width(
                    size * (1 + _familyBorderOverflowFactor * 2),
                    context,
                  ),
                  errorBuilder: (context, error, stackTrace) =>
                      const SizedBox.shrink(),
                ),
              ),
            ),
          Positioned(
            right: badgeOffset.dx,
            bottom: badgeOffset.dy,
            child: Container(
              width: badgeSize,
              height: badgeSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.roseDeep,
                border: Border.all(
                  color: Colors.white,
                  width: badgeBorderWidth,
                ),
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: badgeIconSize,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InitialsTile extends StatelessWidget {
  final String initials;
  final double fontSize;

  const _InitialsTile({required this.initials, this.fontSize = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.blushPaper,
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: 'PlayfairDisplay',
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: AppColors.roseDeep,
        ),
      ),
    );
  }
}
