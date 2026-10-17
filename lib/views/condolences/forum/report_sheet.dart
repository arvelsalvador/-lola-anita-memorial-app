import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/forum/forum_repository.dart';

/// Bottom sheet for reporting a post or reply.
///
/// Returns true when the report was saved, false when it failed,
/// null when dismissed. The caller shows the thank-you / error note.
class ReportSheet extends StatefulWidget {
  final String targetId;
  final String targetKind;
  final bool alreadyReported;
  final Future<ReportSubmitOutcome> Function(String reason, String details)
      onSubmit;

  const ReportSheet({
    super.key,
    required this.targetId,
    required this.targetKind,
    required this.onSubmit,
    this.alreadyReported = false,
  });

  static Future<ReportSubmitOutcome?> show(
    BuildContext context, {
    required String targetId,
    required String targetKind,
    required bool alreadyReported,
    required Future<ReportSubmitOutcome> Function(String reason, String details)
        onSubmit,
  }) {
    return showModalBottomSheet<ReportSubmitOutcome>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ReportSheet(
        targetId: targetId,
        targetKind: targetKind,
        alreadyReported: alreadyReported,
        onSubmit: onSubmit,
      ),
    );
  }

  @override
  State<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<ReportSheet> {
  static const List<String> _reasons = [
    'profanity',
    'inappropriate',
    'spam',
    'other',
  ];

  String _reason = '';
  final TextEditingController _detailsController = TextEditingController();
  bool _submitting = false;
  bool _showReasonError = false;

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  String _reasonLabel(LanguageProvider lang, String reason) {
    return switch (reason) {
      'profanity' => lang.t('forum_report_reason_profanity'),
      'inappropriate' => lang.t('forum_report_reason_inappropriate'),
      'spam' => lang.t('forum_report_reason_spam'),
      _ => lang.t('forum_report_reason_other'),
    };
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    if (_reason.isEmpty) {
      setState(() => _showReasonError = true);
      return;
    }
    setState(() {
      _submitting = true;
      _showReasonError = false;
    });
    HapticFeedback.lightImpact().catchError((_) {});
    try {
      final outcome = await widget.onSubmit(
        _reason,
        _detailsController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(outcome);
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(ReportSubmitOutcome.failed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  width: 38,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.sandBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.flag_outlined,
                    size: 18,
                    color: AppColors.warmMid,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      lang.t('forum_report_title'),
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon:
                        const Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),
              Text(
                lang.t('forum_report_subtitle'),
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.muted,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 12),
              if (widget.alreadyReported)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    lang.t('forum_report_already'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: AppColors.warmMid,
                    ),
                  ),
                ),
              ..._reasons.map(
                (reason) => RadioListTile<String>(
                  value: reason,
                  // ignore: deprecated_member_use
                  groupValue: _reason,
                  // ignore: deprecated_member_use
                  onChanged: _submitting
                      ? null
                      : (value) => setState(() {
                            _reason = value ?? '';
                            _showReasonError = false;
                          }),
                  title: Text(
                    _reasonLabel(lang, reason),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      color: AppColors.textDark,
                    ),
                  ),
                  activeColor: AppColors.warmDark,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                ),
              ),
              if (_showReasonError)
                Text(
                  lang.t('forum_report_require_reason'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.roseDeep,
                  ),
                ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _detailsController,
                  enabled: !_submitting,
                  maxLines: 2,
                  minLines: 1,
                  maxLength: 200,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) =>
                      null,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: lang.t('forum_report_details_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    counterText: '',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _handleSubmit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmDark,
                    foregroundColor: AppColors.linen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _submitting
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.linen,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(lang.t('forum_report_submitting')),
                          ],
                        )
                      : Text(
                          lang.t('forum_report_submit'),
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
