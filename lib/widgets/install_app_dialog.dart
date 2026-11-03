import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:nita/controllers/install_prompt_controller.dart';

/// Pause before the invitation appears, so Home can settle first.
const Duration _installPromptDelay = Duration(seconds: 2);

/// How long a browser may take to announce installability after that pause.
const Duration _browserPromptGrace = Duration(seconds: 10);

/// Shows the gentle install invitation once per browser session.
///
/// Does nothing on Android, iOS, desktop, or when the browser cannot install.
Future<void> showInstallPromptIfEligible(BuildContext context) async {
  // Only a web page can be installed by the browser.
  if (!kIsWeb) return;

  final controller = InstallPromptController.shared;

  try {
    // Listen immediately so an event that arrives during the pause is kept.
    controller.start();

    // Let the home page finish its entrance before interrupting the visitor.
    await Future<void>.delayed(_installPromptDelay);
    if (!context.mounted) return;

    // The one-time guide may be open now. Wait for it to close so two popups
    // never appear on top of each other.
    if (!await _waitForHome(context)) return;

    // Chrome/Edge can announce installability a little late, so give the
    // browser a short grace period before deciding to show nothing.
    final shouldShow = await controller.canShowPrompt(
      browserWait: _browserPromptGrace,
    );
    if (!shouldShow || !context.mounted) return;

    // Remember this session before opening, so a rebuild cannot open a second
    // dialog.
    controller.markShown();

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return InstallAppDialog(
          iosInstructions: controller.needsIosInstructions,
          onInstall: () async {
            // iPhone/iPad Safari has no programmatic install, so the visible
            // Share-sheet instruction is the action; just close the card.
            if (controller.needsIosInstructions) {
              Navigator.of(dialogContext).pop();
              return;
            }

            // Open the browser's native prompt while the tap is still fresh.
            await controller.triggerInstall();
            if (dialogContext.mounted) {
              Navigator.of(dialogContext).pop();
            }
          },
          onNotNow: () async {
            // Close right away, then remember the seven-day choice.
            Navigator.of(dialogContext).pop();
            await controller.snooze();
          },
        );
      },
    );
  } catch (error) {
    // Never let an install-related failure disturb the memorial page.
    debugPrint('InstallPrompt: could not show invitation ($error)');
  }
}

/// Waits until Home is the top route again.
///
/// The one-time guided tour is pushed about 1.5 seconds after Home opens, so a
/// strict two-second timer would otherwise stack the install dialog on top of
/// it. Gives up after two minutes instead of holding the page forever.
Future<bool> _waitForHome(BuildContext context) async {
  for (var attempt = 0; attempt < 60; attempt++) {
    if (!context.mounted) return false;
    if (ModalRoute.of(context)?.isCurrent ?? false) return true;
    await Future<void>.delayed(const Duration(seconds: 2));
  }
  return false;
}

/// The visual "Install this app?" card.
class InstallAppDialog extends StatelessWidget {
  const InstallAppDialog({
    super.key,
    required this.iosInstructions,
    required this.onInstall,
    required this.onNotNow,
  });

  /// True on iPhone/iPad Safari, where the browser has no install prompt.
  final bool iosInstructions;

  /// Opens the browser prompt, or closes the iOS instruction card.
  final VoidCallback onInstall;

  /// Closes the card and remembers the seven-day snooze.
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AlertDialog(
      // Use the app's own warm theme surface instead of a hardcoded color.
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: colors.primaryContainer,
            child: Icon(Icons.home_outlined, color: colors.onPrimaryContainer),
          ),
          const SizedBox(width: 12),
          const Expanded(child: Text('Install this app?')),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Keep Lola Nita's memories close. Install this app on your device "
            'for quick access.',
          ),
          if (iosInstructions) ...[
            const SizedBox(height: 12),
            Text(
              "Tap the Share button, then 'Add to Home Screen'.",
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(onPressed: onNotNow, child: const Text('Not now')),
        FilledButton(
          onPressed: onInstall,
          style: FilledButton.styleFrom(shape: const StadiumBorder()),
          child: Text(iosInstructions ? 'Got it' : 'Install'),
        ),
      ],
    );
  }
}
