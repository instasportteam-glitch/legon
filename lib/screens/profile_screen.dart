import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/media_store.dart';
import '../data/program.dart';
import '../state/app_state.dart';
import '../theme.dart';
import '../ui/format.dart';
import '../ui/widgets.dart';
import '../ui/legion_art.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _changePhoto(BuildContext context) async {
    final app = AppScope.read(context);
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: LegonColors.surface,
      showDragHandle: true,
      useSafeArea: true,
      sheetAnimationStyle: AnimationStyle(
        duration: Motion.sheet,
        reverseDuration: Motion.sheetOut,
      ),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const _SheetAction(
              icon: Icons.photo_camera_outlined,
              label: 'Take photo',
              value: 'camera',
            ),
            const _SheetAction(
              icon: Icons.photo_library_outlined,
              label: 'Choose from library',
              value: 'gallery',
            ),
            if (app.photoPath != null)
              const _SheetAction(
                icon: Icons.delete_outline_rounded,
                label: 'Remove photo',
                value: 'remove',
                destructive: true,
              ),
          ],
        ),
      ),
    );
    if (choice == null) return;
    if (choice == 'remove') {
      await app.setPhoto(null);
      return;
    }
    try {
      final file = await ImagePicker().pickImage(
        source: choice == 'camera' ? ImageSource.camera : ImageSource.gallery,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 1024,
        imageQuality: 88,
      );
      if (file == null) return;
      final path = await persistMedia(file);
      await app.setPhoto(path);
    } catch (_) {
      if (context.mounted) {
        showMessage(
          context,
          'Could not open the ${choice == 'camera' ? 'camera' : 'photo library'}. Check permissions in Settings.',
        );
      }
    }
  }

  Future<void> _editName(BuildContext context) async {
    final app = AppScope.read(context);
    final controller = TextEditingController(text: app.name);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LegonColors.surface,
        title: Text('Your name', style: display(20)),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Marcus'),
          onSubmitted: (v) => Navigator.of(context).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result != null) app.setName(result);
  }

  Future<void> _reset(BuildContext context) async {
    final app = AppScope.read(context);
    // Irreversible and destructive: the one place a confirmation earns its keep.
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: LegonColors.surface,
        title: Text('Reset all progress?', style: display(20)),
        content: Text(
          'This deletes your journal, ranks, custom exercises with their photos and videos, and your profile. '
          'It cannot be undone.',
          style: body(15, color: LegonColors.muted, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Reset',
              style: TextStyle(color: LegonColors.redText),
            ),
          ),
        ],
      ),
    );
    if (ok == true) await app.resetAll();
  }

  @override
  Widget build(BuildContext context) {
    final app = AppScope.of(context);
    final pad = MediaQuery.paddingOf(context);
    final photo = app.photoPath;

    return ListView(
      padding: EdgeInsets.fromLTRB(20, pad.top + 12, 20, pad.bottom + 24),
      children: [
        Text('Profile', style: display(30)),
        const SizedBox(height: 18),
        const LegionArt(asset: LegionArt.legacy, height: 164),
        const SizedBox(height: 16),
        Center(
          child: Pressable(
            onTap: () => _changePhoto(context),
            semanticLabel: photo == null
                ? 'Add profile photo'
                : 'Change profile photo',
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: LegonColors.surface2,
                      border: Border.all(color: LegonColors.gold, width: 3),
                    ),
                    child: ClipOval(
                      child: photo == null
                          ? const Icon(
                              Icons.person_outline_rounded,
                              size: 56,
                              color: LegonColors.dim,
                            )
                          : Image.file(
                              File(photo),
                              key: ValueKey(photo),
                              fit: BoxFit.cover,
                              width: 120,
                              height: 120,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.person_outline_rounded,
                                size: 56,
                                color: LegonColors.dim,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: LegonColors.red,
                        shape: BoxShape.circle,
                        border: Border.all(color: LegonColors.ground, width: 3),
                      ),
                      child: const Icon(
                        Icons.photo_camera_outlined,
                        size: 18,
                        color: LegonColors.ivory,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Center(
          child: Pressable(
            onTap: () => _editName(context),
            semanticLabel: 'Edit name',
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    app.name.isEmpty ? 'Add your name' : app.name,
                    style: body(
                      20,
                      weight: FontWeight.w600,
                      color: app.name.isEmpty
                          ? LegonColors.muted
                          : LegonColors.ivory,
                    ),
                  ),
                  const SizedBox(width: 6),
                  const Icon(
                    Icons.edit_outlined,
                    size: 16,
                    color: LegonColors.muted,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: LegonColors.surface2,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: const Color(0x66D4A95A)),
            ),
            child: Text(
              '${app.rank.name.toUpperCase()} · ${roman(app.rankIndex + 1)}',
              style: display(
                15,
                weight: FontWeight.w700,
                color: LegonColors.goldBright,
                letterSpacing: 0.9,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(child: Text(app.rank.meaning, style: body(14))),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'In the legion since ${formatJoined(app.joined)} · ${app.logs.length} workouts',
            style: body(13, color: LegonColors.muted),
          ),
        ),
        const SizedBox(height: 16),
        ProgressBar(value: app.rankProgress),
        const SizedBox(height: 8),
        Center(
          child: Text(
            app.nextRank == null
                ? 'Highest rank reached'
                : '${app.creditedWorkouts} of ${app.nextRank!.threshold} workouts to ${app.nextRank!.name}',
            style: body(13, color: LegonColors.goldBright),
          ),
        ),
        const SizedBox(height: 24),
        const SectionHeader(
          title: 'Path of ranks',
          trailing: 'earned by workouts',
        ),
        const SizedBox(height: 10),
        LegonCard(
          padding: EdgeInsets.zero,
          radius: 18,
          child: Column(
            children: [
              for (var i = 0; i < ranks.length; i++)
                _RankRow(index: i, current: app.rankIndex),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Pressable(
          onTap: () => _reset(context),
          child: LegonCard(
            radius: 16,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                const Icon(
                  Icons.restart_alt_rounded,
                  color: LegonColors.redText,
                ),
                const SizedBox(width: 12),
                Text(
                  'Reset all progress',
                  style: body(
                    15,
                    weight: FontWeight.w600,
                    color: LegonColors.redText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RankRow extends StatelessWidget {
  const _RankRow({required this.index, required this.current});

  final int index;
  final int current;

  @override
  Widget build(BuildContext context) {
    final r = ranks[index];
    final isCurrent = index == current;
    final earned = index < current;
    final nameColor = isCurrent
        ? LegonColors.goldBright
        : (earned ? LegonColors.ivory : LegonColors.dim);
    final numColor = isCurrent
        ? LegonColors.redText
        : (earned ? LegonColors.gold : LegonColors.dim);
    final meta = isCurrent
        ? 'current'
        : (earned ? 'earned' : '${r.threshold} workouts');
    return Semantics(
      label: '${r.name}, $meta',
      child: ExcludeSemantics(
        child: Container(
          constraints: const BoxConstraints(minHeight: 48),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isCurrent ? LegonColors.raised : Colors.transparent,
            border: index == ranks.length - 1
                ? null
                : const Border(bottom: BorderSide(color: Color(0x14D4A95A))),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40,
                child: Text(
                  roman(index + 1),
                  style: display(14, weight: FontWeight.w700, color: numColor),
                ),
              ),
              Expanded(
                child: Text(r.name, style: display(15, color: nameColor)),
              ),
              Text(
                meta,
                style: body(
                  13,
                  color: isCurrent ? LegonColors.redText : LegonColors.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? LegonColors.redText : LegonColors.ivory;
    return Pressable(
      onTap: () => Navigator.of(context).pop(value),
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Icon(
              icon,
              color: destructive ? LegonColors.redText : LegonColors.gold,
            ),
            const SizedBox(width: 14),
            Text(label, style: body(16, color: color)),
          ],
        ),
      ),
    );
  }
}
