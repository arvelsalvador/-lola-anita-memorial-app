import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:nita/controllers/gallery_controller.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/utils/image_decode.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/core/utils/navigation.dart';
import 'package:nita/core/utils/motion.dart';
import 'package:nita/models/gallery_model.dart';
import 'package:nita/models/gallery_group.dart';
import 'package:nita/widgets/circle_icon_button.dart';
import 'package:nita/widgets/floating_close_button.dart';
import 'package:nita/widgets/ornamental_card.dart';
import 'package:nita/widgets/page_title_header.dart';
import 'package:nita/widgets/photo_counter_pill.dart';
import 'package:nita/widgets/stagger_entrance.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

part 'gallery/gallery_hero_slideshow.dart';
part 'gallery/gallery_grid.dart';
part 'gallery/gallery_lightbox.dart';
part 'gallery/gallery_candle_gate.dart';
part 'gallery/gallery_highlights.dart';

/// Shared top overlay for full-screen photo viewers: a close button
/// (top-right) and a "current / total" counter pill (top-left).
class _ViewerChrome extends StatelessWidget {
  final int current;
  final int total;
  final VoidCallback onClose;

  const _ViewerChrome({
    required this.current,
    required this.total,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          children: [
            const SizedBox(
              width: 38,
            ), // balances the close button's width so the counter stays centered
            Expanded(
              child: Text(
                '${current + 1} / $total',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            _chromeIconButton(icon: Icons.close_rounded, onTap: onClose),
          ],
        ),
      ),
    );
  }

  Widget _chromeIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  final ScrollController? controller;

  /// Reports the active tab index from the home shell. When the value
  /// becomes the gallery tab (1), the "featured" glow state resets.
  final ValueNotifier<int>? activeTab;

  /// Created by the home shell (composition root) and injected here — the
  /// view never constructs or owns the controller.
  final GalleryController galleryController;

  const GalleryPage({
    super.key,
    this.controller,
    this.activeTab,
    required this.galleryController,
  });

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  bool _didInit = false;
  bool _didPrecache = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _didInit = true;
      widget.galleryController.addListener(_onChanged);
      widget.galleryController.load();
    }
  }

  @override
  void didUpdateWidget(covariant GalleryPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Parent rebuilds _buildBodies() every build, but instances are
    // stable in practice. If ever swapped, move the listener so the
    // old controller doesn't leak and the new one still loads.
    if (!identical(oldWidget.galleryController, widget.galleryController)) {
      oldWidget.galleryController.removeListener(_onChanged);
      widget.galleryController.addListener(_onChanged);
      _didPrecache = false;
      widget.galleryController.load();
    }
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {});
    if (!_didPrecache) _precacheFeatured();
  }

  @override
  void dispose() {
    widget.galleryController.removeListener(_onChanged);
    super.dispose();
  }

  Future<void> _precacheFeatured() async {
    if (_didPrecache) return;
    _didPrecache = true;
    final images = widget.galleryController.images;
    if (images == null || images.isEmpty) return;
    // Capture the context before awaiting: the page may pop mid-precache.
    final ctx = context;
    final count = math.min(images.length, 9);
    // No .timeout() here on purpose: Future.timeout leaves a pending
    // Timer in widget tests (fake_async) long after precache finishes,
    // failing teardown with "!timersPending". Bundled-asset precache
    // can't hang like a network call, and errors are caught below.
    try {
      await Future.wait([
        for (int i = 0; i < count; i++)
          // ResizeImage decodes a grid-sized bitmap instead of the full
          // camera JPEG — the lightbox loads a larger tier on demand.
          precacheImage(
            ResizeImage(AssetImage(images[i].path), width: 400),
            ctx,
          ),
      ]);
    } catch (e) {
      debugPrint('[Gallery] precache skipped: $e');
    }
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    // Watch so the empty/loading text re-translates when language changes.
    final lang = context.watch<LanguageProvider>();
    final images = widget.galleryController.images;

    if (images == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (images.isEmpty) {
      // Empty = manifest failed or zero photos. Offer retry instead of
      // a bare text so a Windows stale-bundle or slow manifest isn't
      // a dead end (a full restart picks up new assets).
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                lang.t('no_images'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => widget.galleryController.load(),
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    return GalleryGridView(
      images: images,
      controller: widget.controller,
      activeTab: widget.activeTab,
      galleryController: widget.galleryController,
    );
  }
}
