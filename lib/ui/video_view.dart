import 'dart:io';

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../theme.dart';
import 'widgets.dart';

/// Plays a local video. Tap to play or pause; loops while playing.
class VideoView extends StatefulWidget {
  const VideoView({super.key, required this.path, this.onRemove, this.radius = 22});

  final String path;
  final VoidCallback? onRemove;
  final double radius;

  @override
  State<VideoView> createState() => _VideoViewState();
}

class _VideoViewState extends State<VideoView> {
  late final VideoPlayerController _controller = VideoPlayerController.file(File(widget.path));
  bool _ready = false;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await _controller.initialize();
      await _controller.setLooping(true);
      if (mounted) setState(() => _ready = true);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    if (!_ready) return;
    _controller.value.isPlaying ? _controller.pause() : _controller.play();
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _ready ? _controller.value.aspectRatio.clamp(0.56, 1.78).toDouble() : 16 / 9;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.radius),
      child: AspectRatio(
        aspectRatio: ratio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: LegonColors.surface2),
            if (_ready)
              FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _controller.value.size.width,
                  height: _controller.value.size.height,
                  child: VideoPlayer(_controller),
                ),
              ),
            if (_failed)
              Center(child: Text('This video could not be played', style: body(14, color: LegonColors.muted))),
            if (!_ready && !_failed)
              const Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2, color: LegonColors.gold))),
            if (_ready)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _toggle,
                  child: ValueListenableBuilder<VideoPlayerValue>(
                    valueListenable: _controller,
                    builder: (context, value, _) => AnimatedOpacity(
                      opacity: value.isPlaying ? 0 : 1,
                      duration: Motion.of(context, Motion.fast),
                      child: Center(
                        child: Semantics(
                          button: true,
                          label: value.isPlaying ? 'Pause video' : 'Play video',
                          child: Container(
                            width: 64,
                            height: 64,
                            decoration: const BoxDecoration(color: Color(0xB3140F0C), shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow_rounded, size: 38, color: LegonColors.ivory),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onRemove != null)
              Positioned(
                top: 10,
                right: 10,
                child: Pressable(
                  onTap: widget.onRemove,
                  semanticLabel: 'Remove video',
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(color: Color(0xCC140F0C), shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 20, color: LegonColors.ivory),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
