import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';

/// Bottom sheet for editing your own post or reply text (fix #4).
///
/// Prefilled with the current message. Returns true when the save
/// succeeded, null when dismissed. Failures stay open with a note and
/// keep the typed text so nothing is lost.
class EditTextSheet extends StatefulWidget {
  final String title;
  final String initialText;
  final Future<bool> Function(String message) onSave;

  const EditTextSheet({
    super.key,
    required this.title,
    required this.initialText,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String initialText,
    required Future<bool> Function(String message) onSave,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EditTextSheet(
        title: title,
        initialText: initialText,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EditTextSheet> createState() => _EditTextSheetState();
}

class _EditTextSheetState extends State<EditTextSheet> {
  late final TextEditingController _controller;
  final FocusNode _focus = FocusNode();
  bool _saving = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialText);
    // Desktop/web: Ctrl+Enter (or Cmd+Enter) saves.
    _focus.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (event.logicalKey != LogicalKeyboardKey.enter) {
        return KeyEventResult.ignored;
      }
      if (!(HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed)) {
        return KeyEventResult.ignored;
      }
      _handleSave();
      return KeyEventResult.handled;
    };
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (_saving) return;
    final text = _controller.text.trim();
    if (text.isEmpty || text.length > 1000) {
      setState(() => _showError = true);
      return;
    }
    if (text == widget.initialText.trim()) {
      if (mounted) Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _saving = true;
      _showError = false;
    });
    HapticFeedback.lightImpact().catchError((_) {});
    try {
      final ok = await widget.onSave(text);
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _saving = false;
        _showError = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _showError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 18,
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
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focus,
                  autofocus: true,
                  maxLines: 5,
                  minLines: 3,
                  maxLength: 1000,
                  buildCounter: (
                    _, {
                    required currentLength,
                    required isFocused,
                    maxLength,
                  }) =>
                      null,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: lang.t('forum_content_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (_showError) ...[
                const SizedBox(height: 8),
                Text(
                  lang.t('forum_send_failed'),
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.roseDeep,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: _saving ? null : _handleSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warmDark,
                    foregroundColor: AppColors.linen,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 2,
                  ),
                  child: _saving
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
                            Text(lang.t('forum_post_submitting')),
                          ],
                        )
                      : Text(
                          lang.t('forum_save'),
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
