import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

// On web this picks the JavaScript implementation. On Android, iOS, desktop,
// and tests it picks the do-nothing stub.
import 'install_prompt_stub.dart'
    if (dart.library.js_interop) 'install_prompt_web.dart';

/// Decides whether the gentle "Install this app?" invitation may appear.
class InstallPromptController extends ChangeNotifier {
  InstallPromptController({InstallPromptPlatform? platform})
    : _platform = platform ?? InstallPromptPlatform();

  /// One shared controller for the whole app session.
  ///
  /// Keeping it alive means the browser event listener is attached only once
  /// and the "shown" decision survives a Home page rebuild.
  static final InstallPromptController shared = InstallPromptController();

  /// How long "Not now" silences the invitation.
  static const Duration snoozeDuration = Duration(days: 7);

  /// SharedPreferences key holding the snooze expiry in milliseconds.
  static const String _snoozeUntilKey = 'install_prompt_snoozed_until';

  final InstallPromptPlatform _platform;

  bool _snoozeLoaded = false;
  bool _snoozed = false;
  bool _shownThisSession = false;
  bool _disposed = false;

  /// True when iPhone/iPad Safari needs the Share-sheet instructions.
  bool get needsIosInstructions => _platform.isIosSafari;

  /// Starts listening for the browser's install event.
  void start() {
    if (!kIsWeb || _disposed) return;
    try {
      _platform.listen(_notifyInstallAvailable);
    } catch (error) {
      debugPrint('InstallPrompt: could not start listener ($error)');
    }
  }

  /// Returns true when the invitation can be shown now.
  ///
  /// [browserWait] gives Chrome/Edge a short grace period because their
  /// `beforeinstallprompt` event can arrive a little after the page loads.
  Future<bool> canShowPrompt({Duration browserWait = Duration.zero}) async {
    if (!kIsWeb || _disposed || _shownThisSession) return false;

    try {
      // Already installed and running on its own? Never ask again.
      if (_platform.isStandalone) return false;

      await _loadSnoozeState();
      if (_disposed || _snoozed || _shownThisSession) return false;

      // iPhone/iPad Safari has no install event; show the instruction instead.
      if (_platform.isIosSafari) return true;

      // Chrome/Edge/Android already handed us the native prompt.
      if (_platform.hasDeferredPrompt) return true;

      // Give the browser a short moment to announce installability.
      if (browserWait <= Duration.zero) return false;
      return await _waitForBrowserPrompt(browserWait);
    } catch (error) {
      debugPrint('InstallPrompt: eligibility check failed ($error)');
      return false;
    }
  }

  /// Marks the invitation as used for the rest of this app session.
  void markShown() {
    if (_shownThisSession) return;
    _shownThisSession = true;
    notifyListeners();
  }

  /// Opens the browser's own install prompt.
  Future<bool> triggerInstall() async {
    if (!kIsWeb || _disposed) return false;
    final started = await _platform.triggerInstall();
    if (started) markShown();
    return started;
  }

  /// Remembers "Not now" for seven days.
  Future<void> snooze() async {
    _shownThisSession = true;
    _snoozed = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = DateTime.now().add(snoozeDuration).millisecondsSinceEpoch;
      await prefs.setInt(_snoozeUntilKey, until);
    } catch (error) {
      // Private/in-app browsers can block storage. Close for this visit and
      // simply ask again next time instead of breaking the page.
      debugPrint('InstallPrompt: could not save snooze ($error)');
    }
  }

  /// Reads the saved snooze expiry exactly once.
  Future<void> _loadSnoozeState() async {
    if (_snoozeLoaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final until = prefs.getInt(_snoozeUntilKey);
      _snoozed = until != null && DateTime.now().millisecondsSinceEpoch < until;
    } catch (error) {
      // Unreadable storage counts as "not snoozed" so the visitor is not
      // punished for a browser limitation.
      debugPrint('InstallPrompt: could not read snooze ($error)');
      _snoozed = false;
    } finally {
      _snoozeLoaded = true;
    }
  }

  /// Waits for [browserWait] for a `beforeinstallprompt` event.
  Future<bool> _waitForBrowserPrompt(Duration browserWait) {
    if (_platform.hasDeferredPrompt) return Future<bool>.value(true);

    final completer = Completer<bool>();
    Timer? timer;

    void onChanged() {
      if (_platform.hasDeferredPrompt && !completer.isCompleted) {
        completer.complete(true);
      }
    }

    addListener(onChanged);
    timer = Timer(browserWait, () {
      if (!completer.isCompleted) completer.complete(false);
    });

    return completer.future.whenComplete(() {
      timer?.cancel();
      if (!_disposed) removeListener(onChanged);
    });
  }

  /// Tells the waiting dialog that the browser event just arrived.
  void _notifyInstallAvailable() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _platform.dispose();
    super.dispose();
  }
}
