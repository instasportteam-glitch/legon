import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../theme.dart';

/// Launch loader. Plays the legion intro while app data loads, then
/// cross-fades into [child].
///
/// Rules:
/// - The app opens when BOTH the intro is over and [loading] has finished.
/// - The intro is over when the clip ends, the user taps anywhere to skip,
///   or the video fails / stalls (safety timers), so a broken asset never
///   blocks launch.
/// - With "Reduce Motion" on, a still frame is shown briefly instead.
/// - Playback pauses in the background and resumes on return.
class IntroGate extends StatefulWidget {
  const IntroGate({super.key, required this.loading, required this.child});

  /// Completes when app state is loaded.
  final Future<void> loading;

  /// The app shown after the intro.
  final Widget child;

  @override
  State<IntroGate> createState() => _IntroGateState();
}

class _IntroGateState extends State<IntroGate> with WidgetsBindingObserver {
  static const _video = 'assets/intro/legion_intro.mp4';
  static const _posterStart = 'assets/intro/poster_start.jpg';
  static const _posterLegon = 'assets/intro/poster_legon.jpg';

  /// How long to wait for the video to become playable.
  static const _initTimeout = Duration(seconds: 4);

  /// Still frame duration when Reduce Motion is on.
  static const _reducedHold = Duration(milliseconds: 1200);

  /// Intro → app cross-fade.
  static const _fadeOut = Duration(milliseconds: 450);

  VideoPlayerController? _controller;
  Timer? _safety;

  /// Last controller call still in flight. The controller is disposed only
  /// after it settles: disposing mid-call is what makes video_player throw
  /// "used after being disposed".
  Future<void> _pending = Future.value();

  bool _started = false;
  bool _reduced = false;
  bool _ready = false; // video initialized
  bool _firstFrame = false; // video actually produced a frame
  bool _loaded = false; // app data loaded
  bool _introDone = false; // clip ended / skipped / failed
  bool _gone = false; // intro overlay removed after fade

  bool get _finished => _loaded && _introDone;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    widget.loading.catchError((Object _) {}).whenComplete(() {
      if (!mounted) return;
      setState(() => _loaded = true);
      _onMaybeFinished();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _reduced = Motion.reduced(context);
    if (_reduced) {
      _safety = Timer(_reducedHold, _endIntro);
    } else {
      _initVideo();
    }
  }

  /// Runs a controller call so that disposal waits for it.
  void _run(Future<void> Function(VideoPlayerController c) op) {
    final c = _controller;
    if (c == null) return;
    _pending = _pending.then((_) => op(c)).catchError((Object _) {});
  }

  Future<void> _initVideo() async {
    // Never let the intro hang: if nothing ends it, this does.
    _safety = Timer(_initTimeout, () {
      if (!_ready) _endIntro();
    });
    final c = VideoPlayerController.asset(
      _video,
      videoPlayerOptions: VideoPlayerOptions(
        // Don't stop the user's music; play alongside it.
        mixWithOthers: true,
        // Turns off video_player's own lifecycle observer, which calls
        // play() (and seekTo(0) at the end) on resume. We handle it here.
        allowBackgroundPlayback: true,
      ),
    );
    _controller = c;
    try {
      final init = c.initialize().timeout(_initTimeout);
      _pending = init.catchError((Object _) {});
      await init;
      if (!mounted || _introDone) return;

      c.addListener(_onTick);
      _safety?.cancel();
      // Clip length plus slack, in case the "ended" event never arrives.
      _safety = Timer(c.value.duration + const Duration(seconds: 2), _endIntro);
      setState(() => _ready = true);
      _run((c) => c.play());
    } catch (_) {
      _endIntro();
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || !mounted || _introDone) return;
    final v = c.value;
    if (v.hasError) {
      _endIntro();
      return;
    }
    if (!_firstFrame && v.position > Duration.zero) {
      setState(() => _firstFrame = true);
    }
    final ended = v.isInitialized &&
        v.duration > Duration.zero &&
        v.position >= v.duration - const Duration(milliseconds: 150);
    if (ended) _endIntro();
  }

  void _endIntro() {
    if (_introDone || !mounted) return;
    _safety?.cancel();
    final c = _controller;
    if (c != null && c.value.isPlaying) _run((c) => c.pause());
    setState(() => _introDone = true);
    _onMaybeFinished();
  }

  void _onMaybeFinished() {
    if (!_finished) return;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);
    if (_reduced) _teardown();
  }

  /// Removes the overlay and frees the player once its calls have settled.
  void _teardown() {
    if (_gone) return;
    _safety?.cancel();
    _releaseController();
    if (mounted) setState(() => _gone = true);
  }

  void _releaseController() {
    final c = _controller;
    if (c == null) return;
    _controller = null;
    c.removeListener(_onTick);
    _pending.whenComplete(c.dispose);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_ready || _introDone) return;
    if (state == AppLifecycleState.resumed) {
      _run((c) => c.play());
    } else if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      _run((c) => c.pause());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _safety?.cancel();
    _releaseController();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_finished) return _intro();
    if (_gone) return widget.child;
    return Stack(
      fit: StackFit.expand,
      children: [
        widget.child,
        IgnorePointer(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 1, end: 0),
            duration: _fadeOut,
            curve: Motion.easeOut,
            onEnd: _teardown,
            builder: (context, t, child) => Opacity(opacity: t, child: child),
            child: _intro(),
          ),
        ),
      ],
    );
  }

  /// One video frame (or its poster until the video draws).
  Widget _frame() {
    final c = _controller;
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(_reduced ? _posterLegon : _posterStart, fit: BoxFit.cover, gaplessPlayback: true),
        if (_ready && c != null)
          AnimatedOpacity(
            opacity: _firstFrame ? 1 : 0,
            duration: Motion.fast,
            child: VideoPlayer(c),
          ),
      ],
    );
  }

  Widget _intro() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _introDone ? null : _endIntro,
      child: ColoredBox(
        color: LegonColors.ground,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Backdrop: the same clip, cover-fit and blurred, fills the
            // space around the 16:9 picture on tall screens.
            ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: 28, sigmaY: 28, tileMode: TileMode.clamp),
              child: FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(width: 1280, height: 720, child: _frame()),
              ),
            ),
            const ColoredBox(color: Color(0x59000000)),
            // The clip itself, whole, so nothing at the edges is cut off.
            Center(
              child: AspectRatio(aspectRatio: 16 / 9, child: _frame()),
            ),
          ],
        ),
      ),
    );
  }
}
