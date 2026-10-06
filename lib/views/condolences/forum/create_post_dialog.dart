import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/forum_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _contentController = TextEditingController();
  final VisitorRepository _visitorRepo = const VisitorRepository();

  bool _submitting = false;
  String? _errorMessageKey;

  @override
  void initState() {
    super.initState();
    _loadVisitorInfo();
  }

  Future<void> _loadVisitorInfo() async {
    try {
      final name = await _visitorRepo.localName();
      if (mounted && name != null && name.trim().isNotEmpty) {
        setState(() {
          _nameController.text = name.trim();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameController.text.trim();
    final content = _contentController.text.trim();

    if (name.isEmpty) {
      setState(() => _errorMessageKey = 'forum_require_name');
      return;
    }
    if (content.isEmpty) {
      setState(() => _errorMessageKey = 'forum_require_content');
      return;
    }

    setState(() {
      _submitting = true;
      _errorMessageKey = null;
    });

    HapticFeedback.lightImpact().catchError((_) {});

    await widget.controller.addPost(
      authorName: name,
      message: content,
    );

    if (mounted) {
      Navigator.of(context).pop();
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
                      fontFamily: 'Lora',
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

              // Author Name Field
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.cream,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.3),
                  ),
                ),
                child: TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 14,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: lang.t('forum_name_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Lora',
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                  maxLines: 5,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(
                    fontFamily: 'Lora',
                    fontSize: 14,
                    height: 1.5,
                    color: AppColors.textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: lang.t('forum_content_hint'),
                    hintStyle: const TextStyle(
                      fontFamily: 'Lora',
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
                    fontFamily: 'Lora',
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
                      borderRadius: BorderRadius.circular(12),
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
                            fontFamily: 'Lora',
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
