import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants.dart';
import '../models/search_result.dart';
import '../services/europresse_service.dart';
import 'auth_provider.dart';

class SearchState {
  final String query;
  final List<SearchResult> results;
  final bool isLoading;
  final String? error;
  final int currentPage;
  final bool hasMore;
  final int dateRange;
  final bool searchInTitle;

  const SearchState({
    this.query = '',
    this.results = const [],
    this.isLoading = false,
    this.error,
    this.currentPage = 1,
    this.hasMore = true,
    this.dateRange = AppConstants.dateRangeAll,
    this.searchInTitle = false,
  });

  SearchState copyWith({
    String? query,
    List<SearchResult>? results,
    bool? isLoading,
    String? error,
    int? currentPage,
    bool? hasMore,
    int? dateRange,
    bool? searchInTitle,
  }) => SearchState(
    query: query ?? this.query,
    results: results ?? this.results,
    isLoading: isLoading ?? this.isLoading,
    error: error,
    currentPage: currentPage ?? this.currentPage,
    hasMore: hasMore ?? this.hasMore,
    dateRange: dateRange ?? this.dateRange,
    searchInTitle: searchInTitle ?? this.searchInTitle,
  );
}

class SearchNotifier extends StateNotifier<SearchState> {
  final EuropresseService _europresseService;

  SearchNotifier(this._europresseService) : super(const SearchState());

  void setDateRange(int dateRange) {
    state = state.copyWith(dateRange: dateRange);
  }

  void setSearchInTitle(bool value) {
    state = state.copyWith(searchInTitle: value);
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(
      query: query,
      isLoading: true,
      results: [],
      currentPage: 1,
      hasMore: true,
      error: null,
    );

    try {
      await _europresseService.search(
        keywords: state.searchInTitle ? '' : query,
        titleQuery: state.searchInTitle ? query : '',
        dateRange: state.dateRange,
      );

      final results = await _europresseService.getSearchResults(page: 1);
      state = state.copyWith(
        results: results,
        isLoading: false,
        hasMore: results.length >= AppConstants.docsPerPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (state.isLoading || !state.hasMore) return;

    final nextPage = state.currentPage + 1;
    state = state.copyWith(isLoading: true);

    try {
      final results = await _europresseService.getSearchResults(page: nextPage);
      state = state.copyWith(
        results: [...state.results, ...results],
        isLoading: false,
        currentPage: nextPage,
        hasMore: results.length >= AppConstants.docsPerPage,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

final europresseServiceProvider = Provider<EuropresseService>((ref) {
  return EuropresseService(ref.watch(httpClientProvider));
});

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((ref) {
  return SearchNotifier(ref.watch(europresseServiceProvider));
});
