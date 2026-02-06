import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/article.dart';
import '../services/europresse_service.dart';
import 'search_provider.dart';

class ArticleState {
  final Article? article;
  final bool isLoading;
  final String? error;

  const ArticleState({
    this.article,
    this.isLoading = false,
    this.error,
  });

  ArticleState copyWith({
    Article? article,
    bool? isLoading,
    String? error,
  }) => ArticleState(
    article: article ?? this.article,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class ArticleNotifier extends StateNotifier<ArticleState> {
  final EuropresseService _europresseService;

  ArticleNotifier(this._europresseService) : super(const ArticleState());

  Future<void> loadArticle(String docKey) async {
    state = const ArticleState(isLoading: true);

    try {
      final article = await _europresseService.getArticle(docKey);
      state = ArticleState(article: article, isLoading: false);
    } catch (e) {
      state = ArticleState(isLoading: false, error: e.toString());
    }
  }

  void clear() {
    state = const ArticleState();
  }
}

final articleProvider = StateNotifierProvider<ArticleNotifier, ArticleState>((ref) {
  return ArticleNotifier(ref.watch(europresseServiceProvider));
});
