import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Copies a picked photo or video into the app's documents folder so it
/// survives after the picker's temporary file is cleaned up.
Future<String> persistMedia(XFile file) async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory('${docs.path}/media');
  if (!await dir.exists()) {
    await dir.create(recursive: true);
  }
  final name = file.name;
  final dot = name.lastIndexOf('.');
  final ext = dot >= 0 ? name.substring(dot) : '';
  final target = '${dir.path}/${DateTime.now().microsecondsSinceEpoch}$ext';
  await file.saveTo(target);
  return target;
}

Future<void> deleteMedia(String path) async {
  try {
    final f = File(path);
    if (await f.exists()) {
      await f.delete();
    }
  } catch (_) {
    // A missing file is already the state we want.
  }
}
