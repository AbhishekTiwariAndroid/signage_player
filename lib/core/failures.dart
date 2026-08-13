/// Thrown when a media file could not be fetched after every retry.
class DownloadFailure implements Exception {
  const DownloadFailure(this.url, this.message);

  final String url;
  final String message;

  @override
  String toString() => 'DownloadFailure($url): $message';
}
