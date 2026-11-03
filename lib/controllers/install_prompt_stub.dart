/// Non-web stand-in for the browser install prompt.
///
/// Android, iOS, desktop, and tests compile this file instead of the web
/// implementation, so no JavaScript API is ever referenced there.
class InstallPromptPlatform {
  InstallPromptPlatform();

  /// Native apps are never running inside a browser.
  bool get isStandalone => false;

  /// The iPhone/iPad Safari instructions only make sense on the web.
  bool get isIosSafari => false;

  /// No browser install event exists outside the web.
  bool get hasDeferredPrompt => false;

  /// Registers no listener outside the web.
  void listen(void Function() onAvailable) {}

  /// Releases no listener outside the web.
  void dispose() {}

  /// Outside the web there is no browser prompt to open.
  Future<bool> triggerInstall() async => false;
}
