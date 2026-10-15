import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/forum/spam_guard.dart';
import 'package:nita/data/visitors/visitor_repository.dart';

/// Simple compose sheet for sharing a message, memory, or condolence.
class CreatePostDialog extends StatefulWidget {
  final ForumController controller;

  const CreatePostDialog({super.key, required this.controller});

  static Future<void> show(BuildContext context, {required ForumController controller}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CreatePostDialog(controller: controller),
    );
  }

  @override
  State<CreatePostDialog> createState() => _CreatePostDialogState();
}

class _CreatePostDialogState extends State<CreatePostDialog> {
  final TextEditingController _contentController = TextEditingController();
  final FocusNode _contentFocus = FocusNode();
  final VisitorRepository _visitorRepo = const VisitorRepository();

  bool _submitting = false;
  String? _errorMessageKey;
  String _gateName = '';

  @override
  void initState() {
    super.initState();
    _loadVisitorInfo();
    // Desktop/web: Ctrl+Enter (or Cmd+Enter on macOS) submits the
    // multiline message box without killing paragraph breaks.
    _contentFocus.onKeyEvent = (node, event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (event.logicalKey != LogicalKeyboardKey.enter) {
        return KeyEventResult.ignored;
      }
      if (!(HardwareKeyboard.instance.isControlPressed ||
          HardwareKeyboard.instance.isMetaPressed)) {
        return KeyEventResult.ignored; // plain Enter = newline
      }
      _handleSubmit();
      return KeyEventResult.handled;
    };
  }

  Future<void> _loadVisitorInfo() async {
    try {
      final name = await _visitorRepo.localName();
      if (!mounted) return;
      setState(() {
        _gateName = (name ?? '').trim();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _contentFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    // Identity is locked to the splash-gate name — no per-post editing,
    // so nobody can impersonate another visitor.
    var gateName = _gateName;
    if (gateName.isEmpty) {
      try {
        final fresh = await _visitorRepo.localName();
        gateName = (fresh ?? '').trim();
        if (mounted) setState(() => _gateName = gateName);
      } catch (_) {}
    }
    final content = _contentController.text.trim();

    if (gateName.isEmpty) {
      setState(() => _errorMessageKey = 'forum_require_name');
      return;
    }
    if (content.isEmpty) {
      setState(() => _errorMessageKey = 'forum_require_content');
      return;
    }
    // Spam layer 2: blocklist before anything is sent or stored.
    if (SpamGuard.containsBlockedWords(content)) {
      setState(() => _errorMessageKey = 'forum_blocked_message');
      return;
    }
    // Spam layer 1: 1 post per minute per device.
    final waitSeconds = await SpamGuard.secondsUntilNextPost();
    if (!mounted) return;
    if (waitSeconds > 0) {
      setState(() => _errorMessageKey = 'forum_throttle_post');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessageKey = null;
    });

    HapticFeedback.lightImpact().catchError((_) {});

    try {
      final post = await widget.controller.addPost(
        authorName: gateName,
        message: content,
      );
      if (!mounted) return;
      // Null = save failed: stay open and keep the typed text.
      if (post == null) {
        setState(() {
          _submitting = false;
          _errorMessageKey = 'forum_send_failed';
        });
        return;
      }
      await SpamGuard.recordPost();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _errorMessageKey = 'forum_send_failed';
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
              // Drag bar
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

              // Title Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    lang.t('forum_dialog_title'),
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Content Text Area
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
                  controller: _contentController,
                  focusNode: _contentFocus,
                  maxLines: 5,
                  minLines: 3,
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
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),

              if (_errorMessageKey != null) ...[
                const SizedBox(height: 8),
                Text(
                  lang.t(_errorMessageKey!),
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

              // Submit button
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
                            Text(lang.t('forum_post_submitting')),
                          ],
                        )
                      : Text(
                          lang.t('forum_post_submit'),
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
