import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/constants/donation.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/widgets/ornamental_card.dart';

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
            fontFamily: 'Lora',
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
            fontFamily: 'Lora',
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
class DonationCardBody extends StatelessWidget {
  const DonationCardBody({super.key});

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _QrImage(qrLabel: lang.t('donate_qr_label')),
        const SizedBox(height: 12),
        // const would propagate into DonationDetails access; keep simple.
        // ignore: prefer_const_constructors
        Text(
          DonationDetails.accountName,
          style: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        _NumberRow(
          label: lang.t('donate_number_label'),
          copiedMessage: lang.t('donate_copied'),
          copyLabel: lang.t('donate_copy'),
        ),
        const SizedBox(height: 14),
        _CopyButton(
          copyLabel: lang.t('donate_copy'),
          copiedMessage: lang.t('donate_copied'),
        ),
        const SizedBox(height: 10),
        _OpenGcashButton(label: lang.t('donate_open_gcash')),
        const SizedBox(height: 12),
        Text(
          lang.t('donate_note'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'Lora',
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
  final String qrLabel;
  const _QrImage({required this.qrLabel});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      image: true,
      label: qrLabel,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          DonationDetails.qrAssetPath,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, _, _) => _QrPlaceholder(label: qrLabel),
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
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.fieldFill,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.stoneBorder),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.qr_code_2_rounded, size: 44, color: AppColors.muted),
          const SizedBox(height: 8),
          Text(
            lang.t('donate_missing_qr'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'Lora',
              fontSize: 12,
              fontStyle: FontStyle.italic,
              color: AppColors.warmMid,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberRow extends StatelessWidget {
  final String label;
  final String copiedMessage;
  final String copyLabel;
  const _NumberRow({
    required this.label,
    required this.copiedMessage,
    required this.copyLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Flexible(
          child: Text(
            DonationDetails.gcashNumber,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Lora',
              fontSize: 17,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: AppColors.textDark,
            ),
          ),
        ),
        IconButton(
          tooltip: copyLabel,
          icon: const Icon(Icons.copy_outlined, size: 18),
          color: AppColors.warmMid,
          onPressed: () => copyGcashNumber(context, copiedMessage),
        ),
      ],
    );
  }
}

class _CopyButton extends StatelessWidget {
  final String copyLabel;
  final String copiedMessage;
  const _CopyButton({required this.copyLabel, required this.copiedMessage});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: () => copyGcashNumber(context, copiedMessage),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmDark,
          foregroundColor: AppColors.linen,
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.copy_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                copyLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OpenGcashButton extends StatelessWidget {
  final String label;
  const _OpenGcashButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: OutlinedButton(
        onPressed: () => _openGcash(context),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textDark,
          backgroundColor: Colors.white,
          side: const BorderSide(color: AppColors.stoneBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontFamily: 'Lora',
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.open_in_new_outlined, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      ),
    );
  }

  /// Best-effort GCash deep link. Never throws: falls back to copying the
  /// number so the visitor can paste it inside the GCash app manually.
  Future<void> _openGcash(BuildContext context) async {
    try {
      HapticFeedback.lightImpact().catchError((_) {});
    } catch (_) {
      // Haptics unavailable on desktop —	continue anyway.
    }
    for (final uri in [
      Uri.parse('gcash://'),
      Uri.parse('https://www.gcash.com/'),
    ]) {
      try {
        if (await launchUrl(uri, mode: LaunchMode.externalApplication)) return;
      } catch (_) {
        continue;
      }
    }
    if (!context.mounted) return;
    copyGcashNumber(
      context,
      context.read<LanguageProvider>().t('donate_copied'),
    );
  }
}

/// Copies the GCash number and confirms with a SnackBar. Safe to call from
/// any button — clipboard failures show nothing instead of an error.
Future<void> copyGcashNumber(BuildContext context, String doneMessage) async {
  try {
    await Clipboard.setData(
      const ClipboardData(text: DonationDetails.gcashNumber),
    );
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(doneMessage)));
}
