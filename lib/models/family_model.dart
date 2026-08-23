class FamilyModel {
  /// The center person of the tree — Anita in your screenshot.
  final FamilyMember rootMember;

  /// "32 miyembro ng pamilya"
  final int totalMembers;

  /// "4 na henerasyon"
  final int generations;

  final List<FamilyGroup> groups;

  const FamilyModel({
    required this.rootMember,
    required this.totalMembers,
    required this.generations,
    required this.groups,
  });
}

class FamilyGroup {
  /// Localized label, e.g. 'Mga Anak'.
  final String labelKey;

  /// Subtitle like "3 anak" or "4 kapatid".
  final String subtitleKey;

  /// How many members are in this group (displayed in the group header).
  final int count;

  final List<FamilyMember> members;

  /// True for groups shown as a "view all" card (like Mga Apo, Mga Pamangkin)
  /// instead of listing each member's name + role.
  final bool showAsSummary;

  /// Key for "Tingnan ang lahat ng apo" style text. Only used when
  /// showAsSummary is true.
  final String? viewAllLabelKey;

  const FamilyGroup({
    required this.labelKey,
    required this.subtitleKey,
    required this.count,
    required this.members,
    this.showAsSummary = false,
    this.viewAllLabelKey,
  });
}

class FamilyMember {
  final String name;

  /// Optional portrait asset path, e.g.
  /// 'assets/images/gallery/ramon.jpg'. Null (or a missing file) falls
  /// back to the framed-initials placeholder.
  final String? photoPath;

  /// Localized role label, e.g. 'family_role_husband'.
  final String roleKey;

  /// Short biography about the member (localized).
  final String? bioKey;

  /// A quote this family member shared (localized).
  final String? quoteKey;

  /// Short tag labels shown at the bottom of the member card, e.g. ['ML', 'GL'].
  final List<String> tags;

  /// Number of additional members implied (e.g. "+1 pa").
  final int? extraCount;

  /// e.g. "1938–2022" — only the root member (Anita) needs this.
  final String? yearsLabel;

  /// e.g. 12 for "12 larawan kasama". Nullable — not every member has photos.
  final int? photoCount;

  /// Age in whole years, e.g. 6 — rendered via the localized
  /// 'family_age_years' string. Used in the grandchildren section.
  final int? ageYears;

  /// Age in months (for infants), e.g. 8 — rendered via the localized
  /// 'family_age_months' string. Takes precedence over [ageYears] when
  /// both are set.
  final int? ageMonths;

  /// Short status word shown next to a gold dot, e.g. "Buhay". Null hides
  /// the status dot entirely.
  final String? statusLabel;

  /// A short line shown next to the status, e.g.
  /// "Pinagmumulan ng aming kwento". Null hides this line entirely.
  final String? tagline;

  /// Name of this member's parent, matched against another FamilyMember's
  /// `name` in the same FamilyModel — used only by the canvas tree view to
  /// branch grandchildren under their specific parent. Null means "no
  /// specific parent on record" (the canvas groups these under a shared
  /// row instead of guessing).
  final String? parentName;

  /// This member's spouse, shown as a small "+ Name" subtitle on their
  /// tree card. Purely display text — not a separate linked member.
  final String? spouseName;

  const FamilyMember({
    required this.name,
    required this.roleKey,
    this.photoPath,
    this.bioKey,
    this.quoteKey,
    this.tags = const [],
    this.extraCount,
    this.yearsLabel,
    this.photoCount,
    this.ageYears,
    this.ageMonths,
    this.statusLabel,
    this.tagline,
    this.parentName,
    this.spouseName,
  });
}
