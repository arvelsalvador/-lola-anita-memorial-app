import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';

/// The browser window.
///
/// Only the few members used by this file are declared, so Android and iOS
/// never see any of these JavaScript types.
@JS('window')
external _BrowserWindow get _window;

/// The browser navigator, used to recognize iPhone/iPad Safari and installed
/// standalone web apps.
@JS('navigator')
external _BrowserNavigator get _navigator;

extension type _BrowserWindow._(JSObject _) implements JSObject {
  external _MediaQueryList matchMedia(String query);
  external void addEventListener(String type, JSFunction listener);
  external void removeEventListener(String type, JSFunction listener);
}

extension type _MediaQueryList._(JSObject _) implements JSObject {
  external bool get matches;
}

extension type _BrowserNavigator._(JSObject _) implements JSObject {
  external String get userAgent;
  external int get maxTouchPoints;
  external JSAny? get standalone;
}

/// Chrome/Edge's deferred install event.
///
/// Dart does not ship a type for `BeforeInstallPromptEvent`, so this small
/// extension type describes only the members this app needs.
extension type _BeforeInstallPromptEvent._(JSObject _) implements JSObject {
  external void preventDefault();
  external JSPromise<JSAny?> prompt();
}

/// Web implementation of the browser install prompt.
class InstallPromptPlatform {
  _BeforeInstallPromptEvent? _deferredPrompt;
  JSFunction? _listener;
  void Function()? _onAvailable;

  /// True when the page is already running as an installed app.
  bool get isStandalone {
    try {
      // Chrome, Edge, and Android report installed mode through matchMedia.
      if (_window.matchMedia('(display-mode: standalone)').matches) {
        return true;
      }

      // iPhone/iPad Safari uses its own navigator.standalone flag.
      final iosStandalone = _navigator.standalone;
      return iosStandalone?.dartify() == true;
    } catch (error) {
      // A browser that lacks one of these APIs is simply not standalone.
      debugPrint('InstallPrompt: standalone check failed ($error)');
      return false;
    }
  }

  /// True only for Safari on iPhone or iPad.
  ///
  /// Chrome, Firefox, Edge, and Opera on iOS use their own browser tokens and
  /// cannot add a site to the Home Screen, so they must not receive Safari's
  /// "Share" instructions.
  bool get isIosSafari {
    try {
      final userAgent = _navigator.userAgent;
      final isIos =
          userAgent.contains('iPhone') ||
          userAgent.contains('iPad') ||
          userAgent.contains('iPod') ||
          (_navigator.maxTouchPoints > 1 && userAgent.contains('Macintosh'));
      if (!isIos) return false;

      const otherIosBrowsers = <String>['CriOS', 'FxiOS', 'EdgiOS', 'OPiOS'];
      return !otherIosBrowsers.any(userAgent.contains);
    } catch (error) {
      debugPrint('InstallPrompt: iOS detection failed ($error)');
      return false;
    }
  }

  /// True when the browser has given us a prompt we can open later.
  bool get hasDeferredPrompt {
    // Adopt an event that index.html saved before Flutter started.
    _adoptCapturedPrompt();
    return _deferredPrompt != null;
  }

  /// Starts listening for Chrome/Edge's install announcement.
  void listen(void Function() onAvailable) {
    _onAvailable = onAvailable;
    _adoptCapturedPrompt();

    // A second call must not attach a duplicate browser listener.
    if (_listener != null) return;

    final listener = ((JSAny event) {
      try {
        final promptEvent = _BeforeInstallPromptEvent._(event as JSObject);

        // Stop Chrome's own mini-banner so only our gentle dialog asks.
        promptEvent.preventDefault();

        // Keep the event until the visitor taps "Install".
        _deferredPrompt = promptEvent;
        _onAvailable?.call();
      } catch (error) {
        debugPrint('InstallPrompt: could not read install event ($error)');
      }
    }).toJS;

    _listener = listener;
    _window.addEventListener('beforeinstallprompt', listener);
  }

  /// Opens the browser's native install prompt, if it is still available.
  Future<bool> triggerInstall() async {
    _adoptCapturedPrompt();
    final promptEvent = _deferredPrompt;
    if (promptEvent == null) return false;

    // A beforeinstallprompt event can only be used once.
    _deferredPrompt = null;
    // Drop the early-captured copy too, so it can never be reused.
    _window['__lolaInstallPrompt'] = null;
    try {
      await promptEvent.prompt().toDart;
      return true;
    } catch (error) {
      debugPrint('InstallPrompt: install prompt failed ($error)');
      return false;
    }
  }

  /// Stops listening and forgets the saved event.
  void dispose() {
    final listener = _listener;
    if (listener != null) {
      _window.removeEventListener('beforeinstallprompt', listener);
      _listener = null;
    }
    _onAvailable = null;
    _deferredPrompt = null;
  }

  /// index.html may have saved the event before Flutter started.
  ///
  /// Adopting it here means the popup still works even when Chrome fired the
  /// event during the Flutter boot screen.
  void _adoptCapturedPrompt() {
    if (_deferredPrompt != null) return;
    final captured = _window['__lolaInstallPrompt'];
    if (captured.isA<JSObject>()) {
      _deferredPrompt = _BeforeInstallPromptEvent._(captured as JSObject);
    }
  }
}
