import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Captures a photo from the camera and uploads it to the shared
/// `service-media` bucket, returning its public URL — the same pattern the
/// Services booking form uses for emergency problem photos, factored out
/// so the in-app chat can reuse it. Bytes are read once right after
/// picking (`Uint8List`, never `dart:io File`) so it also works on web.
///
/// Returns null on cancel, no signed-in user, or upload failure — callers
/// treat null as "no photo attached", not an error.
Future<String?> captureAndUploadServiceMedia(
  SupabaseClient client, {
  int imageQuality = 80,
}) async {
  final picked = await ImagePicker().pickImage(
    source: ImageSource.camera,
    imageQuality: imageQuality,
  );
  if (picked == null) return null;

  final Uint8List bytes = await picked.readAsBytes();
  final userId = client.auth.currentUser?.id;
  if (userId == null) return null;

  final path = '$userId/${DateTime.now().microsecondsSinceEpoch}_${picked.name}';
  try {
    await client.storage.from('service-media').uploadBinary(
          path,
          bytes,
          fileOptions: const FileOptions(contentType: 'image/jpeg'),
        );
    return client.storage.from('service-media').getPublicUrl(path);
  } catch (_) {
    return null;
  }
}
