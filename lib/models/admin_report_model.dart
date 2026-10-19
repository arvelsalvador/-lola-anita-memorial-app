/// Outcome of a moderation-report submit, so the UI can tell
/// "already reported" apart from a real failure (e.g. duplicate
/// unique violation after reinstall, vs offline).
enum ReportSubmitOutcome { saved, alreadyReported, failed }

/// One row from `pakikiramay_reports` for the family admin page.
class AdminReportRow {
  final String id;
  final String targetId;
  final String targetKind; // 'post' | 'reply'
  final String reason;
  final String details;
  final String reporterName;
  final DateTime createdAt;

  const AdminReportRow({
    required this.id,
    required this.targetId,
    required this.targetKind,
    required this.reason,
    required this.details,
    required this.reporterName,
    required this.createdAt,
  });
}
