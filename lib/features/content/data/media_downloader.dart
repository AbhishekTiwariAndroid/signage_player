import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../core/constants.dart';
import '../../../core/failures.dart';

class MediaDownloader {
  const MediaDownloader(this._client);

  final http.Client _client;

  /// Throws [DownloadFailure] once all the attempts are used up.
  Future<void> download(String url, String targetPath) async {
    Object? lastError;

    for (var attempt = 0; attempt <= kDownloadRetries; attempt++) {
      try {
        await _fetch(url, targetPath);
        return;
      } on Exception catch (error) {
        lastError = error;
      }
    }

    throw DownloadFailure(url, '$lastError');
  }

  /// Writes to a `.part` file and renames only after the last byte lands, so a
  /// killed download never leaves a truncated file that looks complete.
  Future<void> _fetch(String url, String targetPath) async {
    final partial = File('$targetPath.part');
    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request).timeout(kDownloadTimeout);

    if (response.statusCode != HttpStatus.ok) {
      throw HttpException('HTTP ${response.statusCode}', uri: Uri.parse(url));
    }

    final sink = partial.openWrite();
    try {
      // pipe closes the sink itself once the stream is done
      await response.stream.pipe(sink).timeout(kDownloadTimeout);
    } on Exception {
      await _discard(partial, sink);
      rethrow;
    }

    await partial.rename(targetPath);
  }

  // best effort cleanup so a retry starts from scratch
  Future<void> _discard(File partial, IOSink sink) async {
    try {
      await sink.close();
    } on Exception {
      // already closed by pipe
    }
    try {
      if (await partial.exists()) await partial.delete();
    } on FileSystemException {
      // a leftover .part file is harmless
    }
  }
}
