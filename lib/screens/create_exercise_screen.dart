import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../data/media_store.dart';
import '../data/models.dart';
import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/video_view.dart';
import '../ui/widgets.dart';

/// Opens the "Custom exercise" form as a sheet that rises from the bottom
/// and leaves the same way (drag down or Cancel).
Future<void> showCreateExerciseSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: LegonColors.ground,
    showDragHandle: true,
    sheetAnimationStyle: AnimationStyle(duration: Motion.sheet, reverseDuration: Motion.sheetOut),
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const FractionallySizedBox(heightFactor: 0.96, child: CreateExerciseScreen()),
  );
}

class CreateExerciseScreen extends StatefulWidget {
  const CreateExerciseScreen({super.key});

  @override
  State<CreateExerciseScreen> createState() => _CreateExerciseScreenState();
}

class _CreateExerciseScreenState extends State<CreateExerciseScreen> {
  static const _maxPhotos = 5;

  final _picker = ImagePicker();
  final _name = TextEditingController();
  final _description = TextEditingController();

  MediaKind _kind = MediaKind.video;
  XFile? _video;
  final List<XFile> _photos = [];
  bool _isWarmup = false;
  int _sets = 3;
  int _reps = 12;
  final Set<Muscle> _muscles = {};
  bool _addToToday = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    super.dispose();
  }

  void _error(String what) {
    showMessage(context, 'Could not open $what. Check permissions in Settings.');
  }

  Future<void> _pickVideo(ImageSource source) async {
    try {
      final f = await _picker.pickVideo(source: source, maxDuration: const Duration(seconds: 60));
      if (f != null && mounted) setState(() => _video = f);
    } catch (_) {
      if (mounted) _error(source == ImageSource.camera ? 'the camera' : 'your library');
    }
  }

  Future<void> _pickPhotos(ImageSource source) async {
    final remaining = _maxPhotos - _photos.length;
    if (remaining <= 0) return;
    try {
      if (source == ImageSource.camera) {
        final f = await _picker.pickImage(source: source, maxWidth: 2048, imageQuality: 85);
        if (f != null && mounted) setState(() => _photos.add(f));
      } else {
        final files = await _picker.pickMultiImage(maxWidth: 2048, imageQuality: 85);
        if (!mounted) return;
        setState(() => _photos.addAll(files.take(remaining)));
        if (files.length > remaining) {
          showMessage(context, 'Only $_maxPhotos photos per exercise. The first $remaining were added.');
        }
      }
    } catch (_) {
      if (mounted) _error(source == ImageSource.camera ? 'the camera' : 'your library');
    }
  }

  bool get _canSave => _name.text.trim().isNotEmpty && !_saving;

  Future<void> _save() async {
    if (!_canSave) return;
    setState(() => _saving = true);
    final app = AppScope.read(context);
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    try {
      final paths = <String>[];
      if (_kind == MediaKind.video && _video != null) {
        paths.add(await persistMedia(_video!));
      } else if (_kind == MediaKind.photo) {
        for (final p in _photos) {
          paths.add(await persistMedia(p));
        }
      }
      app.addCustom(CustomExercise(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        description: _description.text.trim(),
        isWarmup: _isWarmup,
        sets: _sets,
        reps: _reps,
        muscles: Set.of(_muscles),
        mediaKind: paths.isEmpty ? null : _kind,
        mediaPaths: paths,
        addToToday: _addToToday,
        createdAt: DateTime.now(),
      ));
      HapticFeedback.mediumImpact();
      navigator.pop();
      messenger.showSnackBar(const SnackBar(content: Text('Saved to My exercises')));
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        showMessage(context, 'Could not save the media. Try again.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, MediaQuery.viewInsetsOf(context).bottom + 32),
        children: [
          Row(
            children: [
              SizedBox(
                width: 80,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Pressable(
                    onTap: () => Navigator.of(context).pop(),
                    child: SizedBox(
                      height: 44,
                      child: Center(child: Text('Cancel', style: body(17, color: LegonColors.goldBright))),
                    ),
                  ),
                ),
              ),
              Expanded(child: Text('Custom exercise', textAlign: TextAlign.center, style: display(18))),
              const SizedBox(width: 80),
            ],
          ),
          const SizedBox(height: 14),
          Segmented(
            labels: const ['Video', 'Photo'],
            index: _kind == MediaKind.video ? 0 : 1,
            onChanged: (i) => setState(() => _kind = i == 0 ? MediaKind.video : MediaKind.photo),
          ),
          const SizedBox(height: 14),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.fast),
            switchInCurve: Motion.easeOut,
            switchOutCurve: Motion.easeOut,
            child: KeyedSubtree(key: ValueKey('${_kind.name}-${_video?.path}-${_photos.length}'), child: _media()),
          ),
          const SizedBox(height: 18),
          _label('Name'),
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'e.g. Shield toss'),
          ),
          const SizedBox(height: 16),
          _label('Description'),
          TextField(
            controller: _description,
            minLines: 4,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(hintText: 'How to perform it, body position, what to watch for'),
          ),
          const SizedBox(height: 16),
          _label('Type'),
          Row(
            children: [
              SelectChip(label: 'Warm-up', selected: _isWarmup, filled: true, onTap: () => setState(() => _isWarmup = true)),
              const SizedBox(width: 8),
              SelectChip(label: 'Strength', selected: !_isWarmup, filled: true, onTap: () => setState(() => _isWarmup = false)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _Stepper(
                  label: 'Sets',
                  value: _sets,
                  onChanged: (v) => setState(() => _sets = v.clamp(1, 10).toInt()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Stepper(
                  label: 'Reps',
                  value: _reps,
                  onChanged: (v) => setState(() => _reps = v.clamp(1, 100).toInt()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _label('Muscle groups'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in Muscle.values)
                SelectChip(
                  label: m.label,
                  selected: _muscles.contains(m),
                  onTap: () => setState(() {
                    if (!_muscles.remove(m)) _muscles.add(m);
                  }),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Pressable(
            onTap: () => setState(() => _addToToday = !_addToToday),
            selected: _addToToday,
            semanticLabel: 'Add to my workouts',
            child: LegonCard(
              radius: 16,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add to my workouts', style: body(15, weight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text('Shows up under "Your additions" in every complex',
                            style: body(13, color: LegonColors.muted)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  LegonSwitch(value: _addToToday),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: _saving ? 'Saving…' : 'Save exercise',
            onTap: _canSave ? _save : null,
            height: 52,
          ),
          if (_name.text.trim().isEmpty) ...[
            const SizedBox(height: 8),
            Center(child: Text('Give the exercise a name to save it', style: body(13, color: LegonColors.dim))),
          ],
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(text, style: body(13, color: LegonColors.muted)),
      );

  Widget _media() {
    if (_kind == MediaKind.video) {
      final video = _video;
      if (video != null) {
        return VideoView(key: ValueKey(video.path), path: video.path, onRemove: () => setState(() => _video = null));
      }
      return _DropZone(
        icon: Icons.videocam_outlined,
        title: 'Show your technique on video',
        primaryLabel: 'Record video',
        onPrimary: () => _pickVideo(ImageSource.camera),
        onSecondary: () => _pickVideo(ImageSource.gallery),
        formats: 'Up to 60 seconds · MP4, MOV',
      );
    }
    if (_photos.isEmpty) {
      return _DropZone(
        icon: Icons.photo_camera_outlined,
        title: 'Add a photo of the position',
        primaryLabel: 'Take photo',
        onPrimary: () => _pickPhotos(ImageSource.camera),
        onSecondary: () => _pickPhotos(ImageSource.gallery),
        formats: 'Up to $_maxPhotos photos · JPG, PNG, HEIC',
      );
    }
    return SizedBox(
      height: 150,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          for (var i = 0; i < _photos.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 10),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.file(File(_photos[i].path), width: 120, height: 150, fit: BoxFit.cover, cacheWidth: 360),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Pressable(
                      semanticLabel: 'Remove photo ${i + 1}',
                      onTap: () => setState(() => _photos.removeAt(i)),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: const BoxDecoration(color: Color(0xCC140F0C), shape: BoxShape.circle),
                        child: const Icon(Icons.close_rounded, size: 18, color: LegonColors.ivory),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          if (_photos.length < _maxPhotos)
            Pressable(
              semanticLabel: 'Add another photo',
              onTap: () => _pickPhotos(ImageSource.gallery),
              child: Container(
                width: 120,
                height: 150,
                decoration: BoxDecoration(
                  color: LegonColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: LegonColors.lineStrong),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.add_rounded, color: LegonColors.gold, size: 28),
                    const SizedBox(height: 4),
                    Text('${_photos.length} / $_maxPhotos', style: body(12, color: LegonColors.muted)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DropZone extends StatelessWidget {
  const _DropZone({
    required this.icon,
    required this.title,
    required this.primaryLabel,
    required this.onPrimary,
    required this.onSecondary,
    required this.formats,
  });

  final IconData icon;
  final String title;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final VoidCallback onSecondary;
  final String formats;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 230,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: LegonColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x80D4A95A), width: 1.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: LegonColors.surface2, shape: BoxShape.circle),
            child: Icon(icon, color: LegonColors.gold, size: 28),
          ),
          const SizedBox(height: 12),
          Text(title, textAlign: TextAlign.center, style: body(15)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Pressable(
                onTap: onPrimary,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: LegonColors.red, borderRadius: BorderRadius.circular(12)),
                  child: Text(primaryLabel, style: body(14, weight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 8),
              SecondaryButton(label: 'From library', onTap: onSecondary),
            ],
          ),
          const SizedBox(height: 10),
          Text(formats, style: body(12, color: LegonColors.muted)),
        ],
      ),
    );
  }
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.label, required this.value, required this.onChanged});

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  Widget _button(String symbol, String semantic, VoidCallback onTap) => Pressable(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        semanticLabel: semantic,
        child: Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: LegonColors.surface2, borderRadius: BorderRadius.circular(12)),
          child: ExcludeSemantics(child: Text(symbol, style: body(22, color: LegonColors.goldBright))),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return LegonCard(
      radius: 16,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: body(13, color: LegonColors.muted)),
          const SizedBox(height: 8),
          Row(
            children: [
              _button('−', 'Fewer ${label.toLowerCase()}', () => onChanged(value - 1)),
              Expanded(
                child: Text('$value', textAlign: TextAlign.center, style: display(22, weight: FontWeight.w700)),
              ),
              _button('+', 'More ${label.toLowerCase()}', () => onChanged(value + 1)),
            ],
          ),
        ],
      ),
    );
  }
}
