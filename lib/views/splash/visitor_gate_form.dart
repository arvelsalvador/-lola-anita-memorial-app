import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/data/visitors/visitor_repository.dart';
import 'package:nita/views/condolences/candle_section.dart';
import 'package:nita/widgets/ornament_divider.dart';

/// Required visitor gate shown over the splash: name + full address.
///
/// Saves locally first (remember-me), calls [onEntered], then syncs to
/// Supabase in the background. Never blocks on network — offline still enters.
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
    final name = _nameController.text;
    final address = _addressController.text;
    final langCode = _langCode(context.read<LanguageProvider>().language);
    // Remember the language choice on-device (fire-and-forget, never
    // throws — see LanguageProvider.saveLanguageCode). The remote
    // visitors row only feeds reports; restore must work offline too.
    unawaited(LanguageProvider.saveLanguageCode(langCode));
    // Only the on-device write gates entry. It is a local storage call,
    // so the guide dialog appears immediately instead of waiting up to
    // 8 seconds for the Supabase insert.
    try {
      await widget.repository.saveVisitorLocal(name: name, address: address);
    } catch (e) {
      // Storage unreadable: still let the visitor in. They may be asked
      // for their name again next launch, but the memorial stays usable.
      debugPrint('VisitorGateForm: local save skipped ($e)');
    }
    if (!mounted) return;
    setState(() => _sending = false);
    widget.onEntered();
    // Upload the visitor row in the background. Never throws, never
    // blocks the UI; it waits for the shared Supabase initialization.
    unawaited(
      widget.repository.syncVisitor(
        name: name,
        address: address,
        lang: langCode,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final nameErrorKey = validateCandleName(_nameController.text);
    final addressErrorKey = VisitorRepository.validateAddress(
      _addressController.text,
    );
    final hasText = _nameController.text.trim().isNotEmpty &&
        _addressController.text.trim().isNotEmpty;
    final isValid = hasText && nameErrorKey == null && addressErrorKey == null;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: AppColors.paper,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.28),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.warmDark.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 4),
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
              fontFamily: 'PlayfairDisplay',
              fontFamilyFallback: ['Times New Roman', 'serif'],
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 10),
          const OrnamentDivider(lineLength: 72, lineAlpha: 0.4),
          const SizedBox(height: 10),
          Text(
            lang.t('visitor_subtitle'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontStyle: FontStyle.italic,
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
                backgroundColor: AppColors.warmDeep,
                foregroundColor: AppColors.linen,
                disabledBackgroundColor: AppColors.muted.withValues(alpha: 0.3),
                shape: const StadiumBorder(),
                textStyle: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
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
        : AppColors.stoneBorder;
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
            color: AppColors.warmMid,
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
              color: AppColors.muted,
            ),
            prefixIcon: Icon(prefixIcon, size: 20, color: AppColors.muted),
            filled: true,
            fillColor: AppColors.fieldPaper,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: error != null
                    ? AppColors.terracotta
                    : AppColors.gold.withValues(alpha: 0.6),
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.terracotta),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
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
