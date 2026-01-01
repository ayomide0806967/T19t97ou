import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

import '../../../core/di/app_providers.dart';
import '../../../features/feed/domain/post_repository.dart';

/// Controller responsible for creating new posts from the compose flow.
class ComposeController extends Notifier<void> {
  @override
  void build() {}

  PostRepository get _repository => ref.read(postRepositoryProvider);

  Future<void> createPost({
    required String author,
    required String handle,
    required String body,
    required List<String> mediaPaths,
  }) async {
    final persistedMedia = await _persistMediaPaths(mediaPaths);
    return _repository.addPost(
      author: author,
      handle: handle,
      body: body,
      mediaPaths: persistedMedia,
    );
  }

  Future<List<String>> _persistMediaPaths(List<String> mediaPaths) async {
    if (mediaPaths.isEmpty) return const <String>[];

    final baseDir = await getApplicationDocumentsDirectory();
    final sep = Platform.pathSeparator;
    final mediaDir = Directory('${baseDir.path}${sep}posted_media');
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    final output = <String>[];
    for (int i = 0; i < mediaPaths.length; i++) {
      final rawPath = mediaPaths[i].trim();
      if (rawPath.isEmpty) continue;

      // If the "path" is actually a URL, keep it as-is.
      final uri = Uri.tryParse(rawPath);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        output.add(rawPath);
        continue;
      }

      final source = File(rawPath);
      if (!await source.exists()) {
        output.add(rawPath);
        continue;
      }

      // If already persisted under our media directory, keep as-is.
      final normalizedDir = mediaDir.absolute.path;
      final normalizedPath = source.absolute.path;
      if (normalizedPath.startsWith(normalizedDir)) {
        output.add(normalizedPath);
        continue;
      }

      final ext = _safeFileExtension(normalizedPath);
      final filename =
          '${DateTime.now().microsecondsSinceEpoch}_${i.toString().padLeft(2, '0')}$ext';
      final destPath = '${mediaDir.path}$sep$filename';

      try {
        final copied = await source.copy(destPath);
        output.add(copied.path);
      } catch (_) {
        // Fall back to the original path if copy fails.
        output.add(rawPath);
      }
    }

    return output;
  }

  String _safeFileExtension(String path) {
    final sep = Platform.pathSeparator;
    final lastSep = path.lastIndexOf(sep);
    final lastDot = path.lastIndexOf('.');
    if (lastDot == -1) return '';
    if (lastSep != -1 && lastDot < lastSep) return '';
    final ext = path.substring(lastDot);
    if (ext.length > 10) return '';
    return ext;
  }
}

final composeControllerProvider =
    NotifierProvider<ComposeController, void>(ComposeController.new);
