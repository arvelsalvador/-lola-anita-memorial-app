import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/donation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/ornament_divider.dart';

/// Abuloy (GCash) section at the bottom of the Pakikiramay tab.
///
/// Static QR + copy-number only — GCash offers no public API for personal
/// accounts, and abuloy is intentionally off-app (direct to the family).
/// Renders a graceful placeholder when the QR asset or real number is not
/// yet configured, so a mourning visitor never sees an error.
class DonationSection extends StatelessWidget {
  const DonationSection({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          height: 1,
          color: AppColors.stoneBorder.withValues(alpha: 0.6),
        ),
        const SizedBox(height: 16),
        Text(
          lang.t('donate_title'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 20,
            height: 1.25,
            fontWeight: FontWeight.w700,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          lang.t('donate_subtitle'),
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontStyle: FontStyle.italic,
            color: AppColors.warmMid,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 14),
        const OrnamentalCard(
          padding: EdgeInsets.all(20),
          child: DonationCardBody(),
        ),
      ],
    );
  }
}

/// The QR + account + copy/open-GCash + note block shared by the
/// Pakikiramay page section and the global assistive-touch dialog.
/// One source of truth — both surfaces stay identical by construction.
///
/// Tapping an account selects it and shows that account's QR on top.
class DonationCardBody extends StatefulWidget {
  const DonationCardBody({super.key});

  @override
  State<DonationCardBody> createState() => _DonationCardBodyState();
}

class _DonationCardBodyState extends State<DonationCardBody> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final selected = DonationDetails.accounts[_selectedIndex];
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _QrImage(
            key: ValueKey(selected.qrAssetPath),
            qrAssetPath: selected.qrAssetPath,
            qrLabel: '${lang.t('donate_qr_label')} — ${selected.accountName}',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          selected.accountName,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 14),
        for (var i = 0; i < DonationDetails.accounts.length; i++) ...[
          _AccountBlock(
            account: DonationDetails.accounts[i],
            copyLabel: lang.t('donate_copy'),
            copiedMessage: lang.t('donate_copied'),
            selected: i == _selectedIndex,
            onTap: () => setState(() => _selectedIndex = i),
          ),
          if (i < DonationDetails.accounts.length - 1)
            const SizedBox(height: 8),
        ],
        const SizedBox(height: 12),
        _OpenGcashButton(
          label: lang.t('donate_open_gcash'),
          account: selected,
          copiedMessage: lang.t('donate_copied'),
        ),
        const SizedBox(height: 10),
        const OrnamentDivider(
          lineLength: 64,
          gap: 8,
          center: OrnamentCenter.leaf,
        ),
        const SizedBox(height: 6),
        Text(
          lang.t('donate_note'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            fontStyle: FontStyle.italic,
            color: AppColors.muted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _QrImage extends StatelessWidget {
  final String qrAssetPath;
  final String qrLabel;
  const _QrImage({super.key, required this.qrAssetPath, required this.qrLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: qrLabel,
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.stoneBorder),
            boxShadow: [
              BoxShadow(
                color: AppColors.warmDark.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              qrAssetPath,
              width: 190,
              height: 190,
              // Contain, not cover: a non-square source JPG must keep its
              // full quiet zone or the QR stops scanning. The card
              // background is already white, so letterboxing is invisible.
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) => _QrPlaceholder(label: qrLabel),
            ),
          ),
        ),
      ),
    );
  }
}

class _QrPlaceholder extends StatelessWidget {
  final String label;
  const _QrPlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.stoneBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: AppColors.paper,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.qr_code_2_rounded,
              size: 20,
              color: AppColors.muted,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              lang.t('donate_missing_qr'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: AppColors.warmMid,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountBlock extends StatelessWidget {
  final DonationAccount account;
  final String copyLabel;
  final String copiedMessage;
  final bool selected;
  final VoidCallback onTap;
  const _AccountBlock({
    required this.account,
    required this.copyLabel,
    required this.copiedMessage,
    this.selected = false,
    required this.onTap,
  });

  String get _initials {
    final parts = account.accountName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.goldLight.withValues(alpha: 0.3)
                : AppColors.paper,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.gold : AppColors.stoneBorder,
              width: selected ? 1.2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.goldLight,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _initials,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warmDeep,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      account.accountName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.displayNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.textDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (selected)
                const Icon(
                  Icons.check_circle_rounded,
                  size: 20,
                  color: AppColors.gold,
                ),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.paper,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.stoneBorder),
                ),
                child: IconButton(
                  tooltip: copyLabel,
                  padding: EdgeInsets.zero,
                  iconSize: 16,
                  icon: const Icon(Icons.copy_outlined),
                  color: AppColors.warmMid,
                  onPressed: () => copyGcashNumber(
                    context,
                    account.copyNumber,
                    copiedMessage,
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

class _OpenGcashButton extends StatelessWidget {
  final String label;
  final DonationAccount account;
  final String copiedMessage;
  const _OpenGcashButton({
    required this.label,
    required this.account,
    required this.copiedMessage,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: () => _openGcash(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmDark,
          foregroundColor: AppColors.linen,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Inter',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new_outlined, size: 18),
            const SizedBox(width: 8),
            Container(
              width: 1,
              height: 18,
              color: AppColors.linen.withValues(alpha: 0.4),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy-then-open: copies the selected number first, then opens GCash.
  ///
  /// Web (GitHub Pages link) cannot jump to the GCash app — browsers block
  /// the `gcash://` scheme — so on web we stop after copying and show a
  /// guide dialog instead of attempting any deep link. Never throws.
  Future<void> _openGcash(BuildContext context) async {
    try {
      HapticFeedback.lightImpact().catchError((_) {});
    } catch (_) {
      // Haptics unavailable on desktop — continue anyway.
    }
    await copyGcashNumber(context, account.copyNumber, copiedMessage);
    if (!context.mounted) return;
    if (kIsWeb) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => _WebGcashGuideDialog(account: account),
      );
      return;
    }
    // Platform-dependent fallback order: on iOS the old fixed order
    // opened the Play Store URL in the browser and never reached the
    // App Store link. Try the GCash app first, then this platform's
    // store; elsewhere (desktop) go straight to the store page.
    // Safe to touch Platform here — the kIsWeb branch returned above.
    final List<Uri> links;
    if (Platform.isIOS) {
      links = [
        Uri.parse('gcash://'),
        Uri.parse('https://apps.apple.com/ph/app/gcash/id520020791'),
      ];
    } else if (Platform.isAndroid) {
      links = [
        Uri.parse('gcash://'),
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.globe.gcash.android',
        ),
      ];
    } else {
      links = [
        Uri.parse(
          'https://play.google.com/store/apps/details?id=com.globe.gcash.android',
        ),
      ];
    }
    for (final uri in links) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (e) {
        debugPrint('DonationSection: could not launch $uri ($e)');
        continue;
      }
    }
  }
}

/// Browser-only guide: explains the number is copied and GCash must be
/// opened on the phone. Offers the QR + a store link in a new tab.
class _WebGcashGuideDialog extends StatelessWidget {
  final DonationAccount account;
  const _WebGcashGuideDialog({required this.account});

  Future<void> _openStore(BuildContext context) async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=com.globe.gcash.android',
    );
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (_) {
      // Stay on the dialog — number/QR already visible for manual use.
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        lang.t('donate_web_title'),
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: AppColors.textDark,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              lang.t('donate_web_body'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.warmMid,
              ),
            ),
            const SizedBox(height: 10),
            _QrImage(
              qrAssetPath: account.qrAssetPath,
              qrLabel:
                  '${lang.t('donate_qr_label')} — ${account.accountName}',
            ),
            const SizedBox(height: 10),
            Text(
              account.displayNumber,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              lang.t('donate_web_step1'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
            Text(
              lang.t('donate_web_step2'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
            Text(
              lang.t('donate_web_step3'),
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                height: 1.5,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(lang.t('donate_close')),
        ),
        ElevatedButton(
          onPressed: () => _openStore(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warmDark,
            foregroundColor: AppColors.linen,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(lang.t('donate_download_gcash')),
        ),
      ],
    );
  }
}

/// Copies the given GCash number and confirms with a SnackBar. Safe to call
/// from any button — clipboard failures show nothing instead of an error.
Future<void> copyGcashNumber(
  BuildContext context,
  String numberToCopy,
  String doneMessage,
) async {
  try {
    await Clipboard.setData(ClipboardData(text: numberToCopy));
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(doneMessage)));
}
