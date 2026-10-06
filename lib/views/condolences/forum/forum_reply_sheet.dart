import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/models/forum_post_model.dart';
import 'package:nita/widgets/gradient_avatar.dart';

/// Modal bottom sheet to view and write replies for a community message.
class ForumReplySheet extends StatefulWidget {
  final ForumPost post;
  final ForumController controller;

  const ForumReplySheet({
    super.key,
    required this.post,
    required this.controller,
  });

  static Future<void> show(
    BuildContext context, {
    required ForumPost post,
    required ForumController controller,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ForumReplySheet(post: post, controller: controller),
    );
  }

  @override
  State<ForumReplySheet> createState() => _ForumReplySheetState();
}

class _ForumReplySheetState extends State<ForumReplySheet> {
  final TextEditingController _replyController = TextEditingController();
  final VisitorRepository _visitorRepo = const VisitorRepository();
  String _visitorName = '';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadVisitorName();
  }

  Future<void> _loadVisitorName() async {
    try {
      final name = await _visitorRepo.localName();
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() => _visitorName = name.trim());
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(BuildContext context, DateTime dateTime) {
    final lang = context.read<LanguageProvider>();
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 60) {
      return lang.t('forum_just_now');
    } else if (diff.inHours < 24) {
      return lang.t('forum_hours_ago', {'count': '${diff.inHours}'});
    } else {
      return lang.t('forum_days_ago', {'count': '${diff.inDays}'});
    }
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return 'A';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return '${parts[0].substring(0, 1)}${parts[1].substring(0, 1)}'.toUpperCase();
  }

  Future<void> _handleSendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _submitting) return;

    setState(() => _submitting = true);
    HapticFeedback.lightImpact().catchError((_) {});

    final author = _visitorName.isEmpty ? 'Anonymous' : _visitorName;
    await widget.controller.addReply(
      postId: widget.post.id,
      authorName: author,
      message: text,
    );

    if (mounted) {
      _replyController.clear();
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    // Get live post state from controller
    final livePost = widget.controller.posts.firstWhere(
      (p) => p.id == widget.post.id,
      orElse: () => widget.post,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: const BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.sandBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lang.t('forum_reply_sheet_title'),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textDark,
                        ),
                      ),
                      Text(
                        lang.t(
                          'forum_replies_count',
                          {'count': '${livePost.replies.length}'},
                        ),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 12,
                          color: AppColors.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: AppColors.muted),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.sandBorder),

          // Thread content
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
              children: [
                // Original Post summary box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cream,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.gold.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          GradientAvatar(
                            initials: _getInitials(livePost.authorName),
                            size: 26,
                            initialsSize: 10,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              livePost.authorName,
                              style: const TextStyle(
                                fontFamily: 'Lora',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        livePost.message,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          height: 1.5,
                          color: AppColors.warmMid,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Replies list
                if (livePost.replies.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        lang.t('forum_no_replies'),
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: AppColors.muted,
                        ),
                      ),
                    ),
                  )
                else
                  ...livePost.replies.map((reply) {
                    final rTimeAgo = _formatTimeAgo(context, reply.createdAt);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GradientAvatar(
                            initials: _getInitials(reply.authorName),
                            size: 28,
                            initialsSize: 11,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.blushPaper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppColors.stoneBorder.withValues(
                                    alpha: 0.6,
                                  ),
                                  width: 0.6,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          reply.authorName,
                                          style: const TextStyle(
                                            fontFamily: 'Lora',
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textDark,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        '• $rTimeAgo',
                                        style: const TextStyle(
                                          fontFamily: 'Lora',
                                          fontSize: 11,
                                          color: AppColors.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    reply.message,
                                    style: const TextStyle(
                                      fontFamily: 'Lora',
                                      fontSize: 13,
                                      height: 1.45,
                                      color: Color(0xFF4A382D),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),

          // Bottom Reply Input
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              decoration: BoxDecoration(
                color: AppColors.paper,
                border: Border(
                  top: BorderSide(
                    color: AppColors.sandBorder.withValues(alpha: 0.7),
                    width: 0.8,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cream,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.gold.withValues(alpha: 0.3),
                        ),
                      ),
                      child: TextField(
                        controller: _replyController,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(
                          fontFamily: 'Lora',
                          fontSize: 13.5,
                          color: AppColors.textDark,
                        ),
                        decoration: InputDecoration(
                          hintText: lang.t('forum_write_reply_hint'),
                          hintStyle: const TextStyle(
                            fontFamily: 'Lora',
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _submitting ? null : _handleSendReply,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.warmDark,
                      foregroundColor: AppColors.linen,
                    ),
                    icon: _submitting
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.linen,
                            ),
                          )
                        : const Icon(Icons.send_rounded, size: 16),
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
