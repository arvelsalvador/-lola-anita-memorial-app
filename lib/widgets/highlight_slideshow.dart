import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:nita/core/constants/app_constants.dart';
import 'package:nita/core/localization/language_provider.dart';
import 'package:nita/models/gallery_model.dart';

class FloatingCloseButton extends StatelessWidget {
  final VoidCallback onPressed;

  const FloatingCloseButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: const Padding(
          padding: EdgeInsets.all(8),
          child: Icon(Icons.close_rounded, size: 22, color: Colors.white),
        ),
      ),
    );
  }
}

class HighlightSlideshow extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;

  const HighlightSlideshow({
    super.key,
    required this.images,
    this.initialIndex = 0,
  });

  @override
  State<HighlightSlideshow> createState() => _HighlightSlideshowState();
}

class _HighlightSlideshowState extends State<HighlightSlideshow> {
  static const _photoDuration = Duration(seconds: 5);

  late int _current = widget.initialIndex;
  bool _playing = true;
  bool _hasMusic = false;
  bool _muted = false;
  Timer? _timer;
  AudioPlayer? _music;

  @override
  void initState() {
    super.initState();
    _initMusic();
    _scheduleNext();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _music?.dispose();
    super.dispose();
  }

  Future<void> _initMusic() async {
    try {
      final assetManifest =
          await AssetManifest.loadFromAssetBundle(rootBundle);
      final audioFiles = assetManifest
          .listAssets()
          .where(
            (key) =>
                key.startsWith('assets/audio/') &&
                (key.endsWith('.mp3') ||
                    key.endsWith('.wav') ||
                    key.endsWith('.m4a')),
          )
          .toList()..sort();
      if (audioFiles.isEmpty) return;

      final path = audioFiles.first;
      final player = AudioPlayer();
      await player.setReleaseMode(ReleaseMode.loop);
      await player.setVolume(0.45);
      await player.play(AssetSource(path.replaceFirst('assets/', '')));
      _music = player;
      if (mounted) setState(() => _hasMusic = true);
    } catch (_) {
      _music?.dispose();
    }
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing) return;
    _timer = Timer(_photoDuration, () {
      if (!mounted) return;
      setState(() => _current = (_current + 1) % widget.images.length);
      _scheduleNext();
    });
  }

  void _goTo(int index) {
    setState(() {
      _current = (index + widget.images.length) % widget.images.length;
    });
    _scheduleNext();
  }

  void _togglePlay() {
    setState(() => _playing = !_playing);
    _scheduleNext();
  }

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _music?.setVolume(_muted ? 0 : 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    final item = widget.images[_current];

    return Scaffold(
      backgroundColor: const Color(0xFF17110D),
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 800),
            switchInCurve: Curves.easeInOut,
            switchOutCurve: Curves.easeOut,
            child: _KenBurnsPhoto(
              key: ValueKey(_current),
              item: item,
              index: _current,
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.55),
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.45),
                ],
                stops: const [0.0, 0.45, 1.0],
              ),
            ),
          ),
          SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 8,
                  right: 12,
                  child: FloatingCloseButton(
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                Center(
                  child: Text(
                    '${_current + 1} / ${widget.images.length}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Column(
                        key: ValueKey(_current),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            lang.t(item.group),
                            style: const TextStyle(
                              fontFamily: 'Georgia',
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                              color: AppColors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${lang.t(item.location ?? 'loc_lipa')}  •  '
                            '${lang.t(item.date ?? 'date_1')}',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _IconButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => _goTo(_current - 1),
                        ),
                        const SizedBox(width: 14),
                        _IconButton(
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          filled: true,
                          onTap: _togglePlay,
                        ),
                        const SizedBox(width: 14),
                        _IconButton(
                          icon: Icons.skip_next_rounded,
                          onTap: () => _goTo(_current + 1),
                        ),
                        if (_hasMusic) ...[
                          const SizedBox(width: 14),
                          _IconButton(
                            icon: _muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            onTap: _toggleMute,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _KenBurnsPhoto extends StatefulWidget {
  final GalleryImageItem item;
  final int index;

  const _KenBurnsPhoto({super.key, required this.item, required this.index});

  @override
  State<_KenBurnsPhoto> createState() => _KenBurnsPhotoState();
}

class _KenBurnsPhotoState extends State<_KenBurnsPhoto>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  )..forward();

  late final Animation<double> _scale =
      Tween<double>(begin: _zoomOut ? 1.14 : 1.0, end: _zoomOut ? 1.0 : 1.14)
          .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  late final Animation<Offset> _pan = Tween<Offset>(
    begin: _panFrom,
    end: _panTo,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

  bool get _zoomOut => widget.index.isOdd;

  Offset get _panFrom => switch (widget.index % 4) {
        0 => const Offset(-0.022, 0),
        1 => const Offset(0.02, 0.014),
        2 => const Offset(0, -0.022),
        _ => const Offset(-0.016, 0.016),
      };

  Offset get _panTo => switch (widget.index % 4) {
        0 => const Offset(0.022, 0),
        1 => const Offset(-0.02, -0.014),
        2 => const Offset(0, 0.022),
        _ => const Offset(0.016, -0.016),
      };

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => FractionalTranslation(
        translation: _pan.value,
        child: Transform.scale(
          scale: _scale.value,
          child: child,
        ),
      ),
      child: Image.asset(
        widget.item.path,
        fit: BoxFit.cover,
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
        errorBuilder: (c, e, s) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final bool filled;

  const _IconButton({
    required this.icon,
    required this.onTap,
    this.size = 22,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? AppColors.white
          : Colors.white.withValues(alpha: 0.14),
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(11),
          child: Icon(
            icon,
            size: size,
            color: filled ? AppColors.warmDark : Colors.white,
          ),
        ),
      ),
    );
  }
}