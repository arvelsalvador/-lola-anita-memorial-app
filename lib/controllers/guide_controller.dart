import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global controller managing onboarding guide visibility, auto-start delays,
/// and persistence of user preferences and seen tour states.
class GuideController extends ChangeNotifier {
  static const String keyGuideEnabled = 'guide_enabled';
  static const String keySeenGuides = 'seen_guides';
  static const String keyHasEnteredInfo = 'visitor_has_entered_info';

  bool _guideEnabled = true;
  final Set<String> _seenGuides;
  bool _hasEnteredInfo = false;

  String _currentTabId = 'home';
  bool _isGuideOpen = false;

  Timer? _autoStartTimer;
  String? _pendingTabId;

  /// Main vertical scroll controller for each tab, registered by the shell.
  ///
  /// The guide uses these to return the page beneath it to the top after the
  /// visitor finishes or skips the tour. The shell owns the controllers; this
  /// map is only a by-tab lookup and is cleared on dispose.
  final Map<String, ScrollController> _scrollControllers =
      <String, ScrollController>{};

  /// Callback registered by the active UI shell (HomePage) to launch the
  /// visual guide modal for [tabId].
  void Function(String tabId)? onStartGuide;

  GuideController({
    bool guideEnabled = true,
    Set<String>? seenGuides,
    bool hasEnteredInfo = false,
  })  : _guideEnabled = guideEnabled,
        _seenGuides = seenGuides ?? <String>{},
        _hasEnteredInfo = hasEnteredInfo;

  bool get guideEnabled => _guideEnabled;
  Set<String> get seenGuides => Set.unmodifiable(_seenGuides);
  bool get hasEnteredInfo => _hasEnteredInfo;
  String get currentTabId => _currentTabId;
  bool get isGuideOpen => _isGuideOpen;

  set isGuideOpen(bool value) {
    if (_isGuideOpen != value) {
      _isGuideOpen = value;
      notifyListeners();
    }
  }

  /// Factory that loads persisted preferences from SharedPreferences before
  /// the UI builds.
  static Future<GuideController> create() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final guideEnabled = prefs.getBool(keyGuideEnabled) ?? true;
      final seenList = prefs.getStringList(keySeenGuides) ?? <String>[];

      // Also check visitor presence:
      final legacyName = prefs.getString('visitor_name')?.trim() ?? '';
      final legacyAddress = prefs.getString('visitor_address')?.trim() ?? '';
      final hasLegacyVisitor =
          legacyName.isNotEmpty && legacyAddress.isNotEmpty;
      final hasEnteredInfo =
          prefs.getBool(keyHasEnteredInfo) ?? hasLegacyVisitor;

      return GuideController(
        guideEnabled: guideEnabled,
        seenGuides: seenList.toSet(),
        hasEnteredInfo: hasEnteredInfo,
      );
    } catch (e) {
      debugPrint('GuideController.create() failed: $e');
      return GuideController();
    }
  }

  void setGuideChoice(bool enabled) {
    _guideEnabled = enabled;
    notifyListeners();
    _saveBool(keyGuideEnabled, enabled);
  }

  void setHasEnteredInfo(bool entered) {
    _hasEnteredInfo = entered;
    notifyListeners();
    _saveBool(keyHasEnteredInfo, entered);
  }

  void markSeen(String tabId) {
    if (_seenGuides.add(tabId)) {
      notifyListeners();
      _saveStringList(keySeenGuides, _seenGuides.toList());
    }
  }

  void resetAll() {
    _seenGuides.clear();
    _guideEnabled = true;
    _autoStartTimer?.cancel();
    notifyListeners();
    _saveBool(keyGuideEnabled, true);
    _saveStringList(keySeenGuides, <String>[]);
  }

  void setCurrentTab(String tabId) {
    if (_currentTabId != tabId) {
      _currentTabId = tabId;
      // If user switches tabs during the delay, cancel it immediately so
      // the guide never appears on the wrong page.
      if (_pendingTabId != tabId) {
        _autoStartTimer?.cancel();
        _autoStartTimer = null;
        _pendingTabId = null;
      }
      notifyListeners();
    }
  }

  void maybeAutoStart(String tabId) {
    _pendingTabId = tabId;
    _autoStartTimer?.cancel();

    if (!_guideEnabled) return;
    if (_seenGuides.contains(tabId)) return;

    _autoStartTimer = Timer(const Duration(milliseconds: 1500), () {
      if (_currentTabId != tabId || _isGuideOpen) return;
      markSeen(tabId);
      onStartGuide?.call(tabId);
    });
  }

  void startManually(String tabId) {
    _autoStartTimer?.cancel();
    _autoStartTimer = null;
    onStartGuide?.call(tabId);
  }

  /// Registers [controller] as the main vertical scroll controller for [tabId].
  ///
  /// Kept separate from the guide itself so every tab follows the same finish
  /// path and the visual guide never owns page state.
  void registerScrollController(String tabId, ScrollController controller) {
    _scrollControllers[tabId] = controller;
  }

  /// Removes [controller] for [tabId] if it is still the registered instance.
  ///
  /// The identity check protects against a shell rebuild registering a newer
  /// controller before the old shell is disposed.
  void unregisterScrollController(String tabId, ScrollController controller) {
    if (identical(_scrollControllers[tabId], controller)) {
      _scrollControllers.remove(tabId);
    }
  }

  /// The single exit path for every guide.
  ///
  /// Marks [tabId] seen, closes the overlay through [closeOverlay], then
  /// returns that tab's page to the top. The scroll is scheduled after the
  /// current frame so the page beneath the overlay is laid out and visible
  /// when the animation begins.
  void onGuideFinished(String tabId, {VoidCallback? closeOverlay}) {
    markSeen(tabId);
    isGuideOpen = false;
    closeOverlay?.call();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = _scrollControllers[tabId];
      if (controller == null || !controller.hasClients) return;

      controller.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    });
    WidgetsBinding.instance.scheduleFrame();
  }

  Future<void> _saveBool(String key, bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, value);
    } catch (e) {
      debugPrint('GuideController: could not write $key ($e)');
    }
  }

  Future<void> _saveStringList(String key, List<String> list) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, list);
    } catch (e) {
      debugPrint('GuideController: could not write $key ($e)');
    }
  }

  @override
  void dispose() {
    _autoStartTimer?.cancel();
    _scrollControllers.clear();
    super.dispose();
  }
}
