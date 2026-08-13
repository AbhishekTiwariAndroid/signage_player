import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../domain/media_item.dart';

/// Owns the media folder and the manifest of what has already been downloaded.
class MediaCacheStore {
  /// [root] defaults to the app documents directory. Tests pass a temp folder
  /// so the cache can be used without a platform channel.
  MediaCacheStore({this.root});

  static const String _directoryName = 'signage_media';
  static const String _manifestName = 'manifest.json';

  final Directory? root;

  Directory? _directory;
  Map<String, String> _manifest = const {};

  /// Safe to call more than once, only the first call does any work.
  Future<void> load() async {
    if (_directory != null) return;

    final base = root ?? await getApplicationDocumentsDirectory();
    final directory = Directory(p.join(base.path, _directoryName));
    await directory.create(recursive: true);

    _directory = directory;
    _manifest = await _readManifest(directory);
  }

  String pathFor(String url, MediaType type) =>
      p.join(_requireDirectory().path, _fileNameFor(url, type));

  /// Null means it still needs downloading. Both the manifest entry and the
  /// file itself have to be there, otherwise a half finished download would
  /// look complete.
  Future<String?> cachedPath(String url, MediaType type) async {
    if (!_manifest.containsKey(url)) return null;

    try {
      final file = File(pathFor(url, type));
      if (!await file.exists()) return null;
      if (await file.length() == 0) return null;
      return file.path;
    } on FileSystemException {
      // treat as not cached and download it again
      return null;
    }
  }

  /// Written once per batch instead of per file, because parallel downloads
  /// would otherwise interleave writes and corrupt the manifest.
  Future<void> rememberAll(Map<String, MediaType> entries) async {
    if (entries.isEmpty) return;

    _manifest = {
      ..._manifest,
      for (final entry in entries.entries)
        entry.key: _fileNameFor(entry.key, entry.value),
    };

    final file = File(p.join(_requireDirectory().path, _manifestName));
    await file.writeAsString(jsonEncode(_manifest), flush: true);
  }

  Directory _requireDirectory() {
    final directory = _directory;
    if (directory == null) {
      throw StateError('MediaCacheStore.load() must be awaited before use.');
    }
    return directory;
  }

  // sha1 keeps the name filesystem safe and always the same for a given url
  String _fileNameFor(String url, MediaType type) {
    final digest = sha1.convert(utf8.encode(url));
    return '$digest${_extensionFor(url, type)}';
  }

  String _extensionFor(String url, MediaType type) {
    final extension = p.extension(Uri.parse(url).path);
    if (extension.isNotEmpty && extension.length <= 5) return extension;
    return type == MediaType.video ? '.mp4' : '.jpg';
  }

  Future<Map<String, String>> _readManifest(Directory directory) async {
    final file = File(p.join(directory.path, _manifestName));
    if (!await file.exists()) return const {};

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) return const {};
      return {
        for (final entry in decoded.entries) '${entry.key}': '${entry.value}',
      };
    } on FormatException {
      // a broken manifest just means everything gets downloaded again
      return const {};
    } on FileSystemException {
      return const {};
    }
  }
}
