import 'dart:io';

import 'package:background_downloader/background_downloader.dart';

/// Bridges `background_downloader` records to the rest of the app: which books
/// have downloaded chapters, and where those files live on disk.
class DownloadsService {
  /// Strips path separators / traversal so a hostile archive.org `identifier`
  /// or file `name` can't write outside the book's download folder.
  static String sanitizeSegment(String input, {String fallback = 'file'}) {
    final cleaned =
        input.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_').replaceAll('..', '_');
    return cleaned.isEmpty ? fallback : cleaned;
  }

  static String directoryFor(String bookId) =>
      'audiobooks/${sanitizeSegment(bookId, fallback: 'book')}';

  static String fileNameFor(String? chapterName, {required String fallback}) =>
      sanitizeSegment(chapterName ?? fallback, fallback: fallback);

  static String taskIdFor(String bookId, String chapterName) =>
      '$bookId-$chapterName';

  Future<List<TaskRecord>> _completed() async {
    final records = await FileDownloader().database.allRecords();
    return records.where((r) => r.status == TaskStatus.complete).toList();
  }

  /// Book identifiers that have at least one downloaded chapter whose file is
  /// still present on disk. (Verifying existence keeps the Library in sync with
  /// the book-detail page, which also checks the files.)
  Future<Set<String>> downloadedBookIds() async {
    const prefix = 'audiobooks/';
    final ids = <String>{};
    for (final record in await _completed()) {
      final dir = record.task.directory;
      if (!dir.startsWith(prefix)) continue;
      final id = dir.substring(prefix.length);
      if (id.isEmpty || ids.contains(id)) continue;
      final path = await record.task.filePath();
      if (await File(path).exists()) ids.add(id);
    }
    return ids;
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
      if (await File(path).exists()) {
        result[record.task.filename] = path;
      }
    }
    return result;
  }

  /// Total size on disk of all completed downloads, in bytes.
  Future<int> totalDownloadedBytes() async {
    var total = 0;
    for (final record in await _completed()) {
      try {
        final file = File(await record.task.filePath());
        if (await file.exists()) total += await file.length();
      } catch (_) {/* skip */}
    }
    return total;
  }

  /// Deletes every downloaded file and forgets all records.
  Future<void> deleteAll() async {
    for (final record in await FileDownloader().database.allRecords()) {
      try {
        final file = File(await record.task.filePath());
        if (await file.exists()) await file.delete();
      } catch (_) {/* best-effort */}
    }
    await FileDownloader().database.deleteAllRecords();
  }

  /// Deletes a single downloaded chapter's file and forgets its record.
  Future<void> deleteChapter(String bookId, String? chapterName) async {
    final dir = directoryFor(bookId);
    final fname = fileNameFor(chapterName, fallback: '');
    final records = await FileDownloader().database.allRecords();
    for (final record in records
        .where((r) => r.task.directory == dir && r.task.filename == fname)) {
      try {
        final file = File(await record.task.filePath());
        if (await file.exists()) await file.delete();
      } catch (_) {/* best-effort */}
      await FileDownloader().database.deleteRecordWithId(record.task.taskId);
    }
  }

  /// Deletes all downloaded files for a book and forgets their records.
  Future<void> deleteBook(String bookId) async {
    final dir = directoryFor(bookId);
    final records = await FileDownloader().database.allRecords();
    for (final record in records.where((r) => r.task.directory == dir)) {
      try {
        final file = File(await record.task.filePath());
        if (await file.exists()) await file.delete();
      } catch (_) {
        // ignore: best-effort cleanup
      }
      await FileDownloader().database.deleteRecordWithId(record.task.taskId);
    }
  }
}
