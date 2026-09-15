part of '../settings_page.dart';

/// Projects: the one portfolio entry this memorial can verify —
/// the memorial app itself.
class _ProjectsPage extends StatelessWidget {
  const _ProjectsPage();

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return _DetailScaffold(
      title: lang.t('settings_dev_projects_title'),
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.gold,
        borderAlpha: 0.2,
        borderWidth: 0.6,
        shadowOpacity: 0.06,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.eco, size: 22, color: AppColors.gold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    lang.t('app_title'),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                      fontFamily: 'Georgia',
                      fontFamilyFallback: ['Times New Roman', 'serif'],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              lang.t('settings_dev_project_memorial_body'),
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _TechChip(icon: Icons.flutter_dash, label: 'Flutter'),
                _TechChip(icon: Icons.code_rounded, label: 'Dart'),
                _TechChip(
                  icon: Icons.local_fire_department_rounded,
                  label: 'Firebase',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              lang.t('settings_about_app_version'),
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contact Us: intro plus a name / email / message form. Sending opens
/// the mail app with everything prefilled (photo sharing stays out
/// until an upload backend exists). Falls back to copying the message
/// when no mail app exists, so the button never dies quietly.
class _ContactPage extends StatefulWidget {
  const _ContactPage();

  @override
  State<_ContactPage> createState() => _ContactPageState();
}

class _ContactPageState extends State<_ContactPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_onChanged);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _messageController.removeListener(_onChanged);
    _messageController.dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _send() async {
    final messenger = ScaffoldMessenger.of(context);
    final lang = context.read<LanguageProvider>();
    final message = _messageController.text.trim();
    if (message.isEmpty) return;
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final signature = [
      if (name.isNotEmpty) name,
      if (email.isNotEmpty) email,
    ].join(' · ');
    final body = signature.isEmpty ? message : '$message\n\n— $signature';
    // No family inbox configured yet: copy to clipboard so words are
    // never lost to a placeholder address.
    if (kFamilyEmail.isNotEmpty) {
      final uri = Uri(
        scheme: 'mailto',
        path: kFamilyEmail,
        queryParameters: {'subject': 'Para kay Nanay', 'body': body},
      );
      try {
        if (await canLaunchUrl(uri).timeout(const Duration(seconds: 5))) {
          await launchUrl(uri).timeout(const Duration(seconds: 5));
          if (!mounted) return;
          messenger.showSnackBar(
            SnackBar(
              content: Text(lang.t('settings_contact_opening')),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      } catch (e) {
        debugPrint('[Contact] mailto failed, clipboard fallback: $e');
      }
    }
    try {
      await Clipboard.setData(
        ClipboardData(text: body),
      ).timeout(const Duration(seconds: 5));
    } catch (e) {
      debugPrint('[Contact] clipboard failed: $e');
    }
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(lang.t('settings_contact_copied')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final canSend = _messageController.text.trim().isNotEmpty;
    return _DetailScaffold(
      title: lang.t('settings_contact_title'),
      child: OrnamentalCard(
        radius: 16,
        borderColor: AppColors.gold,
        borderAlpha: 0.2,
        borderWidth: 0.6,
        shadowOpacity: 0.06,
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              lang.t('settings_contact_intro'),
              style: AppTextStyles.bodyText,
            ),
            const SizedBox(height: 18),
            _FieldLabel(text: lang.t('settings_contact_name_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _nameController,
              hint: lang.t('settings_contact_name_hint'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            _FieldLabel(text: lang.t('settings_contact_email_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _emailController,
              hint: lang.t('settings_contact_email_hint'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 14),
            _FieldLabel(text: lang.t('settings_contact_message_label')),
            const SizedBox(height: 6),
            _ContactField(
              controller: _messageController,
              hint: lang.t('settings_contact_message_hint'),
              maxLines: 5,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: Material(
                color: Colors.transparent,
                child: Ink(
                  decoration: BoxDecoration(
                    gradient: canSend
                        ? const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.devCopper,
                              AppColors.devCopperDeep,
                            ],
                          )
                        : null,
                    color: canSend ? null : AppColors.muted,
                    borderRadius: BorderRadius.circular(99),
                    boxShadow: canSend
                        ? [
                            BoxShadow(
                              color: AppColors.warmDark.withValues(alpha: 0.2),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: canSend ? _send : null,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.send_outlined,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            lang.t('settings_contact_send_message'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 14,
                    color: AppColors.rose,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      lang.t('settings_contact_privacy'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: AppColors.muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small semibold label above a contact field.
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: AppColors.textDark,
        fontFamily: 'Georgia',
        fontFamilyFallback: ['Times New Roman', 'serif'],
      ),
    );
  }
}

/// Warm filled text field shared by the contact form.
class _ContactField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;

  const _ContactField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      minLines: 1,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      style: const TextStyle(fontSize: 14, color: AppColors.textDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 14, color: AppColors.muted),
        filled: true,
        fillColor: AppColors.fieldPaper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.rose, width: 1),
        ),
      ),
    );
  }
}
