part of '../gallery_page.dart';

class HighlightSlideshow extends StatefulWidget {
  final List<GalleryImageItem> images;
  final int initialIndex;

  /// Injected controller — the view only triggers playback; locating the
  /// bundled audio file happens in the controller.
  final GalleryController galleryController;

  const HighlightSlideshow({
    super.key,
    required this.images,
    required this.galleryController,
    this.initialIndex = 0,
  });

  @override
  State<HighlightSlideshow> createState() => _HighlightSlideshowState();
}

class _HighlightSlideshowState extends State<HighlightSlideshow> {
  static const _photoDuration = Duration(seconds: 5);

  late int _current = widget.images.isEmpty
      ? 0
      : widget.initialIndex.clamp(0, widget.images.length - 1);
  bool _playing = true;
  bool _hasMusic = false;
  bool _muted = false;
  Timer? _timer;
  AudioPlayer? _music;
  // Guards the async music lifecycle: set in dispose so late
  // continuations never touch a dead player, and bumped per track switch
  // so rapid taps can't interleave stop()/play() calls.
  bool _disposed = false;
  int _musicOp = 0;

  // All bundled tracks available to pick from, and which one is
  // currently playing — powers the new music-picker bottom sheet.
  List<String> _availableTracks = [];
  String? _currentTrackPath;

  @override
  void initState() {
    super.initState();
    _initMusic();
    _scheduleNext();
  }

  @override
  void dispose() {
    _disposed = true;
    _musicOp++;
    _timer?.cancel();
    final music = _music;
    _music = null;
    music?.dispose();
    super.dispose();
  }

  Future<void> _initMusic() async {
    try {
      final tracks = await widget.galleryController.findAllAudioAssets();
      if (_disposed || !mounted || tracks.isEmpty) return;
      setState(() => _availableTracks = tracks);

      final defaultPath = await widget.galleryController.findFirstAudioAsset();
      if (_disposed || !mounted) return;
      final startPath = defaultPath ?? tracks.first;

      final player = AudioPlayer();
      _music = player;
      await player.setReleaseMode(ReleaseMode.loop);
      if (_disposed) {
        await player.dispose();
        return;
      }
      await player.setVolume(0.45);
      if (_disposed) {
        await player.dispose();
        return;
      }
      await player.play(AssetSource(startPath));
      if (_disposed || !mounted) return;
      setState(() {
        _hasMusic = true;
        _currentTrackPath = startPath;
      });
    } catch (_) {
      if (_disposed) return;
      final music = _music;
      _music = null;
      music?.dispose();
    }
  }

  /// Switches background music to [path] without interrupting the photo
  /// slideshow itself — stops the current track and starts the new one
  /// at the same volume/mute state, keeping playback logic identical to
  /// what _initMusic already sets up. Rapid taps are serialized via
  /// [_musicOp]: only the latest request takes effect.
  Future<void> _selectTrack(String path) async {
    final op = ++_musicOp;
    final music = _music;
    if (path == _currentTrackPath || music == null) return;
    try {
      await music.stop();
      if (_disposed || !mounted || op != _musicOp) return;
      await music.play(AssetSource(path));
      if (_disposed || !mounted || op != _musicOp) return;
      await music.setVolume(_muted ? 0 : 0.45);
      if (_disposed || !mounted || op != _musicOp) return;
      setState(() => _currentTrackPath = path);
    } catch (_) {
      // Leave the previous track playing if switching fails, rather than
      // silently killing music the visitor was already enjoying.
    }
  }

  void _showTrackPicker() {
    final lang = context.read<LanguageProvider>();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.viewerBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('gallery_choose_music'),
                  style: const TextStyle(
                    fontFamily: 'PlayfairDisplay',
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: AppColors.paper,
                  ),
                ),
                const SizedBox(height: 8),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _availableTracks.length,
                    separatorBuilder: (_, _) => Divider(
                      color: Colors.white.withValues(alpha: 0.08),
                      height: 1,
                    ),
                    itemBuilder: (context, index) {
                      final path = _availableTracks[index];
                      final selected = path == _currentTrackPath;
                      final title = path
                          .split('/')
                          .last
                          .replaceAll(RegExp(r'\.(mp3|wav|m4a)$'), '');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          selected
                              ? Icons.play_circle_fill_rounded
                              : Icons.music_note_rounded,
                          color: selected ? AppColors.gold : Colors.white54,
                        ),
                        title: Text(
                          title,
                          style: TextStyle(
                            color: selected ? AppColors.gold : Colors.white,
                            fontWeight: selected
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                        trailing: selected
                            ? const Icon(
                                Icons.check_rounded,
                                color: AppColors.gold,
                              )
                            : null,
                        onTap: () {
                          _selectTrack(path);
                          Navigator.of(sheetContext).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _scheduleNext() {
    _timer?.cancel();
    if (!_playing || widget.images.isEmpty) return;
    _timer = Timer(_photoDuration, () {
      if (!mounted || widget.images.isEmpty) return;
      setState(() => _current = (_current + 1) % widget.images.length);
      _scheduleNext();
    });
  }

  void _goTo(int index) {
    if (widget.images.isEmpty) return;
    setState(() {
      _current = (index + widget.images.length) % widget.images.length;
    });
    _scheduleNext();
  }

  void _togglePlay() {
    if (widget.images.isEmpty) return;
    setState(() => _playing = !_playing);
    _scheduleNext();
  }

  void _toggleMute() {
    if (_disposed) return;
    setState(() => _muted = !_muted);
    _music?.setVolume(_muted ? 0 : 0.45);
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<LanguageProvider>();
    if (widget.images.isEmpty) {
      return const Scaffold(
        backgroundColor: AppColors.viewerBackground,
        body: Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      );
    }
    final item = widget.images[_current.clamp(0, widget.images.length - 1)];

    return Scaffold(
      backgroundColor: AppColors.viewerBackground,
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
                // Photo counter pinned to the top-left so it never sits
                // over the middle of the image.
                Positioned(
                  top: 12,
                  left: 12,
                  child: PhotoCounterPill(
                    current: _current,
                    total: widget.images.length,
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
                            lang.t(item.group.key),
                            style: const TextStyle(
                              fontFamily: 'PlayfairDisplay',
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                              color: AppColors.paper,
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
                        CircleIconButton(
                          icon: Icons.skip_previous_rounded,
                          onTap: () => _goTo(_current - 1),
                        ),
                        const SizedBox(width: 14),
                        CircleIconButton(
                          icon: _playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          size: 30,
                          filled: true,
                          onTap: _togglePlay,
                        ),
                        const SizedBox(width: 14),
                        CircleIconButton(
                          icon: Icons.skip_next_rounded,
                          onTap: () => _goTo(_current + 1),
                        ),
                        if (_hasMusic) ...[
                          const SizedBox(width: 14),
                          CircleIconButton(
                            icon: _muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            onTap: _toggleMute,
                          ),
                          if (_availableTracks.length > 1) ...[
                            const SizedBox(width: 14),
                            CircleIconButton(
                              icon: Icons.library_music_rounded,
                              onTap: _showTrackPicker,
                            ),
                          ],
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
  // Static opening frame when the OS requests reduced motion.
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 5200),
  );

  @override
  void initState() {
    super.initState();
    if (!animationsDisabled()) _controller.forward();
  }

  late final Animation<double> _scale = Tween<double>(
    begin: _zoomOut ? 1.14 : 1.0,
    end: _zoomOut ? 1.0 : 1.14,
  ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

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
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: Image.asset(
        widget.item.path,
        fit: BoxFit.cover,
        // Absolute pixel decode budget for the zoomable Ken Burns slideshow
        // (not a logical size — same reasoning as _lightboxWidth).
        cacheWidth: 1200,
        filterQuality: FilterQuality.medium,
        errorBuilder: (c, e, s) => const Center(
          child: Icon(Icons.broken_image, size: 80, color: Colors.grey),
        ),
      ),
    );
  }
}
