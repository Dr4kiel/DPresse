import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/article.dart';

class BookmarksNotifier extends StateNotifier<List<Article>> {
  static const _storageKey = 'bookmarks';

  BookmarksNotifier() : super([]) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final list = jsonDecode(json) as List;
      state = list.map((e) => Article.fromJson(e as Map<String, dynamic>)).toList();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> addBookmark(Article article) async {
    if (state.any((a) => a.id == article.id)) return;
    state = [...state, article];
    await _save();
  }

  Future<void> removeBookmark(String articleId) async {
    state = state.where((a) => a.id != articleId).toList();
    await _save();
  }

  bool isBookmarked(String articleId) {
    return state.any((a) => a.id == articleId);
  }
}

final bookmarksProvider = StateNotifierProvider<BookmarksNotifier, List<Article>>((ref) {
  return BookmarksNotifier();
});
