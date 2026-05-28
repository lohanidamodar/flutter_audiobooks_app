import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

/// Bridges `background_downloader` records to the rest of the app: which books
/// have downloaded chapters, and where those files live on disk.
class DownloadsService {
  static String directoryFor(String bookId) => 'audiobooks/$bookId';
  static String taskIdFor(String bookId, String chapterName) =>
      '$bookId-$chapterName';

  Future<List<TaskRecord>> _completed() async {
    final records = await FileDownloader().database.allRecords();
    return records.where((r) => r.status == TaskStatus.complete).toList();
  }

  /// Book identifiers that have at least one completed chapter download.
  Future<Set<String>> downloadedBookIds() async {
    const prefix = 'audiobooks/';
    final records = await _completed();
    return records
        .map((r) => r.task.directory)
        .where((d) => d.startsWith(prefix))
        .map((d) => d.substring(prefix.length))
        .where((id) => id.isNotEmpty)
        .toSet();
  }

  Future<int> downloadedChapterCount(String bookId) async {
    final dir = directoryFor(bookId);
    final records = await _completed();
    return records.where((r) => r.task.directory == dir).length;
  }

  /// Map of `chapter filename -> absolute local path` for a book, including
  /// only files that still exist on disk.
  Future<Map<String, String>> localPathsForBook(String bookId) async {
    final dir = directoryFor(bookId);
    final result = <String, String>{};
    for (final record in await _completed()) {
      if (record.task.directory != dir) continue;
      final path = await record.task.filePath();
      if (File(path).existsSync()) {
        result[record.task.filename] = path;
      }
    }
    return result;
  }
}
