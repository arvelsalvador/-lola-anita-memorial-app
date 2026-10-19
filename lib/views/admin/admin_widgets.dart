part of 'admin_page.dart';

/// Real page header: transparent, roomy back + title + divider.
class _AdminHeader extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onPinSettings;
  final VoidCallback onHistory;

  const _AdminHeader({
    required this.onBack,
    required this.onPinSettings,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleIconButton(
                  icon: Icons.arrow_back_rounded,
                  onTap: onBack,
                  size: 20,
                  buttonSize: 44,
                  backgroundColor: AppColors.mistPaper,
                  foregroundColor: AppColors.warmDeep,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _adminText('admin_reports_title'),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textDark,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _adminText('admin_reports_subtitle'),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Tooltip(
                  message: 'History',
                  child: CircleIconButton(
                    icon: Icons.history_rounded,
                    onTap: onHistory,
                    size: 20,
                    buttonSize: 44,
                    backgroundColor: AppColors.mistPaper,
                    foregroundColor: AppColors.warmDeep,
                  ),
                ),
                const SizedBox(width: 8),
                Tooltip(
                  message: _adminText('admin_change_pin'),
                  child: CircleIconButton(
                    icon: Icons.lock_outline_rounded,
                    onTap: onPinSettings,
                    size: 20,
                    buttonSize: 44,
                    backgroundColor: AppColors.mistPaper,
                    foregroundColor: AppColors.warmDeep,
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.only(top: 14),
              child: Divider(height: 1, color: AppColors.stoneBorder),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented pill tab bar: mist container, white selected pill,
/// each tab with a small count badge (hidden when the count is 0).
class _SegmentedTabs extends StatelessWidget {
  final List<String> tabs;
  final List<int> counts;
  final int selected;
  final ValueChanged<int> onSelect;

  const _SegmentedTabs({
    required this.tabs,
    required this.counts,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < tabs.length; i++)
            Expanded(
              child: GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color:
                            selected == i ? Colors.white : Colors.transparent,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: selected == i
                              ? AppColors.stoneBorder.withValues(alpha: 0.6)
                              : Colors.transparent,
                        ),
                        boxShadow: selected == i
                            ? [
                                BoxShadow(
                                  color:
                                      Colors.black.withValues(alpha: 0.07),
                                  blurRadius: 5,
                                  offset: const Offset(0, 1),
                                ),
                              ]
                            : null,
                      ),
                      child: Text(
                        tabs[i],
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12,
                          fontWeight: selected == i
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected == i
                              ? AppColors.textDark
                              : AppColors.muted,
                        ),
                      ),
                    ),
                    if (i < counts.length && counts[i] > 0)
                      Positioned(
                        top: -7,
                        right: 2,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 1,
                          ),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.roseDeep,
                            borderRadius: BorderRadius.circular(9),
                            border: Border.all(
                              color: Colors.white,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 3,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Text(
                            counts[i] > 99 ? '99+' : '${counts[i]}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              height: 1.2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// White rounded search field.
class _AdminSearch extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _AdminSearch({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 13.5,
          color: AppColors.textDark,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13.5,
            color: AppColors.muted,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 19,
            color: AppColors.muted,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

/// Avatar circle with initials.
class _AdminAvatar extends StatelessWidget {
  final String name;
  final double size;

  const _AdminAvatar({required this.name, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _adminAvatarColor(name),
      ),
      child: Center(
        child: Text(
          _adminInitials(name),
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size * 0.36,
            fontWeight: FontWeight.w700,
            color: AppColors.warmDeep,
          ),
        ),
      ),
    );
  }
}

/// Bottom action row: quiet left button + filled delete right button.
class _AdminActionRow extends StatelessWidget {
  final IconData leftIcon;
  final String leftLabel;
  final VoidCallback? onLeft;
  final String rightLabel;
  final VoidCallback? onRight;
  final bool busy;

  const _AdminActionRow({
    required this.leftIcon,
    required this.leftLabel,
    required this.onLeft,
    required this.rightLabel,
    required this.onRight,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 44,
            child: TextButton.icon(
              onPressed: busy ? null : onLeft,
              icon: Icon(leftIcon, size: 15),
              label: Text(
                leftLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.warmDeep,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              onPressed: busy ? null : onRight,
              icon: busy
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.delete_outline_rounded, size: 15),
              label: Text(
                rightLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.roseDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Base white card shared by every admin list.
class _AdminCard extends StatelessWidget {
  final Widget child;

  const _AdminCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: child,
      ),
    );
  }
}

/// Small muted chip (kind, date).
class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.warmDeep,
        ),
      ),
    );
  }
}

/// Report card: avatar row, message, reason chips, reporters, actions.
class _ReportCard extends StatelessWidget {
  final _ReportedGroup group;
  final bool busy;
  final String Function(String code) reasonLabel;
  final VoidCallback onDelete;
  final VoidCallback onDismiss;

  const _ReportCard({
    required this.group,
    required this.busy,
    required this.reasonLabel,
    required this.onDelete,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final missing = group.message == null;
    final name = (group.authorName ?? '').isEmpty
        ? 'Anonymous'
        : group.authorName!;
    final reasons = group.reports
        .map((r) => reasonLabel(r.reason.isEmpty ? 'other' : r.reason))
        .toSet()
        .toList();
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      group.messageAt == null
                          ? _adminDate(group.latest)
                          : _adminDateTime(group.messageAt!),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              _MetaChip(
                label: '${group.reports.length} report${group.reports.length == 1 ? '' : 's'}',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final reason in reasons)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.roseDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    reason,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.roseDeep,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (missing)
            Text(
              _adminText('admin_reports_deleted_target'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontStyle: FontStyle.italic,
                color: AppColors.muted,
              ),
            )
          else
            Text(
              group.message ?? '',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          for (final r in group.reports)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                '${r.reporterName} · ${_adminDate(r.createdAt)}${r.details.isNotEmpty ? ' — ${r.details}' : ''}',
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.muted,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.check_rounded,
            leftLabel: _adminText('admin_report_dismiss'),
            onLeft: onDismiss,
            rightLabel: _adminText('admin_report_delete'),
            onRight: missing ? null : onDelete,
            busy: busy,
          ),
        ],
      ),
    );
  }
}

/// Message card for the Messages and Private tabs.
class _AdminMessageCard extends StatelessWidget {
  final String title;
  final String message;
  final String date;
  final String badge;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String repliesLabel;
  final List<Widget> replyTiles;

  const _AdminMessageCard({
    required this.title,
    required this.message,
    required this.date,
    required this.badge,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    required this.repliesLabel,
    required this.replyTiles,
  });

  @override
  Widget build(BuildContext context) {
    final name = title.isEmpty ? 'Anonymous' : title;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$badge · $date',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.textDark,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.edit_outlined,
            leftLabel: _adminText('admin_report_edit'),
            onLeft: onEdit,
            rightLabel: _adminText('admin_report_delete'),
            onRight: onDelete,
            busy: busy,
          ),
          if (replyTiles.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '${repliesLabel.isEmpty ? 'Replies' : repliesLabel} (${replyTiles.length})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: AppColors.muted,
              ),
            ),
            ...replyTiles,
          ],
        ],
      ),
    );
  }
}

class _AdminReplyTile extends StatelessWidget {
  final String name;
  final String message;
  final String date;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _AdminReplyTile({
    required this.name,
    required this.message,
    required this.date,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final display = name.isEmpty ? 'Anonymous' : name;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: display, size: 30),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      display,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    Text(
                      date,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              height: 1.45,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _SmallAdminButton(
                  icon: Icons.edit_outlined,
                  onTap: busy ? null : onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SmallAdminButton(
                  icon: Icons.delete_outline_rounded,
                  color: AppColors.roseDeep,
                  onTap: busy ? null : onDelete,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Plain avatar + text card for Visitors and Private tabs.
/// When [showAsAddress] is true (visitors roster), the body renders as a
/// small muted location row instead of message-style text.
class _PlainAdminCard extends StatelessWidget {
  final String badge;
  final String date;
  final String title;
  final String message;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final bool showAsAddress;

  /// Optional language chip for the Visitors tab (English/Tagalog/Bicol).
  /// Null on every other caller, so those cards stay exactly as before.
  final String? langLabel;

  const _PlainAdminCard({
    required this.badge,
    required this.date,
    required this.title,
    required this.message,
    required this.busy,
    required this.onEdit,
    required this.onDelete,
    this.showAsAddress = false,
    this.langLabel,
  });

  @override
  Widget build(BuildContext context) {
    final name = title.isEmpty ? 'Anonymous' : title;
    return _AdminCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AdminAvatar(name: name),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$badge · $date',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11.5,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
              if (langLabel != null) ...[
                const SizedBox(width: 8),
                _MetaChip(label: langLabel!),
              ],
            ],
          ),
          const SizedBox(height: 8),
          if (showAsAddress)
            if (message.isNotEmpty)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 1),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 14,
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 12.5,
                        height: 1.45,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              )
            else
              const SizedBox.shrink()
          else
            Text(
              message,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13.5,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.stoneBorder),
          ),
          _AdminActionRow(
            leftIcon: Icons.edit_outlined,
            leftLabel: showAsAddress
                ? _adminText('admin_visitor_edit')
                : _adminText('admin_report_edit'),
            onLeft: onEdit,
            rightLabel: showAsAddress
                ? _adminText('admin_visitor_delete')
                : _adminText('admin_report_delete'),
            onRight: onDelete,
            busy: busy,
          ),
        ],
      ),
    );
  }
}

class _SmallAdminButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _SmallAdminButton({
    required this.icon,
    this.color = AppColors.textDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: AppColors.stoneBorder.withValues(alpha: 0.8),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: EdgeInsets.zero,
        ),
        child: Icon(icon, size: 15),
      ),
    );
  }
}

/// Reason pills for the Reports tab: All / curse words / inappropriate /
/// spam / other. Horizontally scrollable because the labels vary in
/// length. Additive UI — the other admin tabs keep their own layout.
class _ReportReasonChips extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;

  const _ReportReasonChips({
    required this.labels,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.mistPaper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.stoneBorder.withValues(alpha: 0.7),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onSelect(i),
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected == i ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: selected == i
                          ? AppColors.stoneBorder.withValues(alpha: 0.6)
                          : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    labels[i],
                    maxLines: 1,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11.5,
                      fontWeight: selected == i
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: selected == i
                          ? AppColors.textDark
                          : AppColors.muted,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

