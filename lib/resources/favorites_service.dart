import 'package:shared_preferences/shared_preferences.dart';

/// Stores favourited book ids as an ordered list (newest first) in prefs.
class FavoritesService {
  static const _key = 'favorites.ids';
  final SharedPreferences _prefs;
  FavoritesService(this._prefs);

  List<String> ids() => _prefs.getStringList(_key) ?? const [];

  bool isFavorite(String id) => ids().contains(id);

  Future<List<String>> toggle(String id) async {
    final list = ids().toList();
    if (list.contains(id)) {
      list.remove(id);
    } else {
      list.insert(0, id);
    }
    await _prefs.setStringList(_key, list);
    return list;
  }
}
