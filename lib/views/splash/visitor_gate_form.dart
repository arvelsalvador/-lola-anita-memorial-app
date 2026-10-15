import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/condolences/candle_section.dart';

/// Required visitor gate shown over the splash: name + full address.
///
/// Saves locally first (remember-me), syncs to Supabase in background,
/// then calls [onEntered]. Never blocks on network — offline still enters.
class VisitorGateForm extends StatefulWidget {
  final VoidCallback onEntered;
  final VisitorRepository repository;

  const VisitorGateForm({
    super.key,
    required this.onEntered,
    VisitorRepository? repository,
  }) : repository = repository ?? const _DefaultRepo();

  @override
  State<VisitorGateForm> createState() => _VisitorGateFormState();
}

/// Default wiring so tests can inject a fake repository.
class _DefaultRepo extends VisitorRepository {
  const _DefaultRepo();
}

class _VisitorGateFormState extends State<VisitorGateForm> {
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  bool _sending = false;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_refresh);
    _addressController.addListener(_refresh);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  String _langCode(AppLanguage lang) => switch (lang) {
        AppLanguage.english => 'en',
        AppLanguage.tagalog => 'tl',
        AppLanguage.bicol => 'bi',
      };

  /// Returns the error key to display, or null when the field is still
  /// pristine. Live feedback after typing, full errors after submit.
  String? _shownKey(String text, String? errorKey) {
    if (errorKey == null) return null;
    if (text.trim().isNotEmpty || _submitted) return errorKey;
    return null;
  }

  Future<void> _submit() async {
    if (_sending) return;
    if (validateCandleName(_nameController.text) != null ||
        VisitorRepository.validateAddress(_addressController.text) != null) {
      setState(() => _submitted = true);
      return;
    }
    setState(() => _sending = true);
    FocusManager.instance.primaryFocus?.unfocus();
    final langCode =
        _langCode(context.read<LanguageProvider>().language);
    // Local save always succeeds; remote sync never throws.
    await widget.repository.saveVisitor(
      name: _nameController.text,
      address: _addressController.text,
      lang: langCode,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onEntered();
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nameErrorKey = validateCandleName(_nameController.text);
    final addressErrorKey =
        VisitorRepository.validateAddress(_addressController.text);
    final isValid = nameErrorKey == null && addressErrorKey == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            lang.t('visitor_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A1A),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            lang.t('visitor_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          _GateField(
            controller: _nameController,
            label: lang.t('visitor_name_label'),
            hint: lang.t('visitor_name_hint'),
            prefixIcon: Icons.person_outline,
            error: switch (_shownKey(_nameController.text, nameErrorKey)) {
              null => null,
              final key => lang.t(key),
            },
            textCapitalization: TextCapitalization.words,
          ),
          const SizedBox(height: 14),
          _GateField(
            controller: _addressController,
            label: lang.t('visitor_address_label'),
            hint: lang.t('visitor_address_hint'),
            prefixIcon: Icons.location_on_outlined,
            error: switch (_shownKey(
              _addressController.text,
              addressErrorKey,
            )) {
              null => null,
              final key => lang.t(key),
            },
            textCapitalization: TextCapitalization.sentences,
          ),
          if (!isValid &&
              (_submitted ||
                  _nameController.text.trim().isNotEmpty ||
                  _addressController.text.trim().isNotEmpty)) ...[
            const SizedBox(height: 8),
            Text(
              lang.t('visitor_required'),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.warmMid,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: (isValid && !_sending) ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.warmDark,
                foregroundColor: AppColors.linen,
                disabledBackgroundColor:
                    AppColors.muted.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: _sending
                  ? Text(lang.t('visitor_sending'))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(lang.t('visitor_enter')),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: AppColors.gold,
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 14),
          _PrivacyNote(
            icon: Icons.visibility_outlined,
            text: lang.t('visitor_privacy_candle'),
          ),
          const SizedBox(height: 4),
          _PrivacyNote(
            icon: Icons.lock_outline,
            text: lang.t('visitor_privacy_private'),
          ),
        ],
      ),
    );
  }
}

class _GateField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final String? error;
  final TextCapitalization textCapitalization;

  const _GateField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    required this.textCapitalization,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = error != null
        ? AppColors.terracotta
        : const Color(0xFFE0E0E0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          textCapitalization: textCapitalization,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            color: AppColors.textDark,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              color: Color(0xFF9E9E9E),
            ),
            prefixIcon: Icon(
              prefixIcon,
              size: 20,
              color: const Color(0xFF9E9E9E),
            ),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.terracotta
                    : AppColors.gold.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.terracotta,
                width: 1.5,
              ),
            ),
          ),
        ),
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(
            error!,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              color: AppColors.terracotta,
            ),
          ),
        ],
      ],
    );
  }
}

class _PrivacyNote extends StatelessWidget {
  final IconData icon;
  final String text;

  const _PrivacyNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: AppColors.muted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 11.5,
              color: AppColors.muted,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
