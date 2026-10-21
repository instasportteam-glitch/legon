import 'dart:io';

import 'package:flutter/material.dart';

import '../state/app_state.dart';
import '../theme.dart';
import '../ui/format.dart';
import '../ui/video_view.dart';
import '../ui/widgets.dart';

class CustomExerciseScreen extends StatelessWidget {
  const CustomExerciseScreen({super.key, required this.id});

  final String id;

  Future<void> _delete(BuildContext context) async {
    final app = AppScope.read(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LegonColors.surface,
        title: Text('Delete this exercise?', style: display(20)),
        content: Text('Its photos or video will be removed from the app too.',
            style: body(15, color: LegonColors.muted, height: 1.4)),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: LegonColors.redText)),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    Navigator.of(context).pop();
    await app.deleteCustom(id);
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final matches = app.customs.where((c) => c.id == id);
    final pad = MediaQuery.paddingOf(context);
    if (matches.isEmpty) {
      return const Scaffold(body: SizedBox.shrink());
    }
    final ex = matches.first;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.fromLTRB(20, pad.top + 4, 20, pad.bottom + 32),
        children: [
          const Align(alignment: Alignment.centerLeft, child: BackLink(label: 'Journal')),
          const SizedBox(height: 8),
          if (ex.hasVideo)
            VideoView(path: ex.mediaPaths.first)
          else if (ex.hasPhotos)
            _PhotoPager(paths: ex.mediaPaths),
          if (ex.hasVideo || ex.hasPhotos) const SizedBox(height: 18),
          Text(ex.isWarmup ? 'YOUR WARM-UP' : 'YOUR EXERCISE', style: eyebrow(color: LegonColors.redText)),
          const SizedBox(height: 6),
          Text(ex.name, style: display(28)),
          const SizedBox(height: 4),
          Text('Added ${formatJoined(ex.createdAt)}', style: body(13, color: LegonColors.muted)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: StatTile(label: 'Sets', value: '${ex.sets}')),
              const SizedBox(width: 8),
              Expanded(child: StatTile(label: 'Reps', value: '${ex.reps}')),
            ],
          ),
          if (ex.description.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'How to perform'),
            const SizedBox(height: 8),
            Text(ex.description, style: body(15, height: 1.5)),
          ],
          if (ex.muscles.isNotEmpty) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'Muscle groups'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final m in ex.muscles)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: LegonColors.raised,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: LegonColors.gold),
                    ),
                    child: Text(m.label, style: body(14, color: LegonColors.goldBright)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          Pressable(
            onTap: () => app.setAddToToday(ex.id, !ex.addToToday),
            selected: ex.addToToday,
            semanticLabel: 'Add to my workouts',
            child: LegonCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(child: Text('Add to my workouts', style: body(15, weight: FontWeight.w600))),
                  LegonSwitch(value: ex.addToToday),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Pressable(
            onTap: () => _delete(context),
            child: LegonCard(
              radius: 16,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Icon(Icons.delete_outline_rounded, color: LegonColors.redText),
                  const SizedBox(width: 12),
                  Text('Delete exercise', style: body(15, weight: FontWeight.w600, color: LegonColors.redText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PhotoPager extends StatefulWidget {
  const _PhotoPager({required this.paths});

  final List<String> paths;

  @override
  State<_PhotoPager> createState() => _PhotoPagerState();
}

class _PhotoPagerState extends State<_PhotoPager> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: AspectRatio(
            aspectRatio: 4 / 5,
            child: PageView.builder(
              itemCount: widget.paths.length,
              onPageChanged: (i) => setState(() => _page = i),
              itemBuilder: (context, i) => Image.file(
                File(widget.paths[i]),
                fit: BoxFit.cover,
                semanticLabel: 'Photo ${i + 1} of ${widget.paths.length}',
                errorBuilder: (_, __, ___) => const ColoredBox(
                  color: LegonColors.surface2,
                  child: Center(child: Icon(Icons.image_not_supported_outlined, color: LegonColors.dim)),
                ),
              ),
            ),
          ),
        ),
        if (widget.paths.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < widget.paths.length; i++)
                AnimatedContainer(
                  duration: Motion.of(context, Motion.fast),
                  curve: Motion.easeOut,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: i == _page ? 18 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i == _page ? LegonColors.gold : LegonColors.track,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
