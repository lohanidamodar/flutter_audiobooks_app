import 'package:shared_preferences/shared_preferences.dart';

class Bookmark {
  final int chapterIndex;
  final Duration position;
  const Bookmark({required this.chapterIndex, required this.position});
}

class PlaybackBookmarks {
  PlaybackBookmarks._();
  static final PlaybackBookmarks instance = PlaybackBookmarks._();

  static const _prefix = 'bookmark::';

  Future<Bookmark?> load(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    final chapter = prefs.getInt('$_prefix$bookId::chapter');
    final ms = prefs.getInt('$_prefix$bookId::ms');
    if (chapter == null || ms == null) return null;
    return Bookmark(
      chapterIndex: chapter,
      position: Duration(milliseconds: ms),
    );
  }

  Future<void> save(String bookId, Bookmark bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_prefix$bookId::chapter', bookmark.chapterIndex);
    await prefs.setInt(
      '$_prefix$bookId::ms',
      bookmark.position.inMilliseconds,
    );
    await prefs.setString('$_prefix$bookId::ts',
        DateTime.now().toIso8601String());
  }

  Future<List<String>> recentBookIds({int limit = 10}) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = <MapEntry<String, DateTime>>[];
    for (final key in prefs.getKeys()) {
      if (!key.startsWith(_prefix) || !key.endsWith('::ts')) continue;
      final ts = DateTime.tryParse(prefs.getString(key) ?? '');
      if (ts == null) continue;
      final id = key.substring(_prefix.length, key.length - 4);
      entries.add(MapEntry(id, ts));
    }
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(limit).map((e) => e.key).toList();
  }

  Future<void> clear(String bookId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefix$bookId::chapter');
    await prefs.remove('$_prefix$bookId::ms');
    await prefs.remove('$_prefix$bookId::ts');
  }
}
