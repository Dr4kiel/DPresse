import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/feed.dart';
import '../models/feed_item.dart';
import '../services/rss_service.dart';

// Default feeds
const _defaultFeeds = [
  Feed(
    id: 'liberation',
    name: 'Libération',
    url: 'https://www.liberation.fr/arc/outboundfeeds/rss-all/collection/accueil-une/?outputType=xml',
  ),
  Feed(
    id: 'lemonde-international',
    name: 'Le Monde - International',
    url: 'https://www.lemonde.fr/international/rss_full.xml',
  ),
  Feed(
    id: 'lemonde-france',
    name: 'Le Monde - France',
    url: 'https://www.lemonde.fr/politique/rss_full.xml',
  ),
  Feed(
    id: 'lemonde-economie',
    name: 'Le Monde - Économie',
    url: 'https://www.lemonde.fr/economie/rss_full.xml',
  ),
  Feed(
    id: 'lemonde-culture',
    name: 'Le Monde - Culture',
    url: 'https://www.lemonde.fr/culture/rss_full.xml',
  ),
  Feed(
    id: 'lemonde-sport',
    name: 'Le Monde - Sport',
    url: 'https://www.lemonde.fr/sport/rss_full.xml',
  ),
  Feed(
    id: 'monde-diplomatique',
    name: 'Le Monde Diplomatique',
    url: 'https://www.monde-diplomatique.fr/recents.xml',
  ),
  Feed(
    id: 'courrier-international',
    name: 'Courrier International',
    url: 'https://www.courrierinternational.com/feed/all/rss.xml',
  ),
];

class FeedsState {
  final List<Feed> feeds;
  final Map<String, List<FeedItem>> feedItems;
  final bool isLoading;
  final String? error;

  const FeedsState({
    this.feeds = const [],
    this.feedItems = const {},
    this.isLoading = false,
    this.error,
  });

  FeedsState copyWith({
    List<Feed>? feeds,
    Map<String, List<FeedItem>>? feedItems,
    bool? isLoading,
    String? error,
  }) => FeedsState(
    feeds: feeds ?? this.feeds,
    feedItems: feedItems ?? this.feedItems,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );
}

class FeedsNotifier extends StateNotifier<FeedsState> {
  static const _storageKey = 'feeds';
  final RssService _rssService;

  FeedsNotifier(this._rssService) : super(const FeedsState()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_storageKey);
    if (json != null) {
      final list = jsonDecode(json) as List;
      state = state.copyWith(
        feeds: list.map((e) => Feed.fromJson(e as Map<String, dynamic>)).toList(),
      );
    } else {
      state = state.copyWith(feeds: _defaultFeeds);
      await _save();
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(state.feeds.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, json);
  }

  Future<void> refreshFeeds() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final enabledFeeds = state.feeds.where((f) => f.enabled).toList();
      final items = <String, List<FeedItem>>{};

      await Future.wait(enabledFeeds.map((feed) async {
        final feedItems = await _rssService.fetchFeed(feed.url, feed.name);
        items[feed.id] = feedItems.take(5).toList();
      }));

      state = state.copyWith(feedItems: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addFeed(Feed feed) async {
    state = state.copyWith(feeds: [...state.feeds, feed]);
    await _save();
  }

  Future<void> removeFeed(String feedId) async {
    state = state.copyWith(
      feeds: state.feeds.where((f) => f.id != feedId).toList(),
    );
    await _save();
  }

  Future<void> toggleFeed(String feedId) async {
    state = state.copyWith(
      feeds: state.feeds.map((f) {
        if (f.id == feedId) return f.copyWith(enabled: !f.enabled);
        return f;
      }).toList(),
    );
    await _save();
  }
}

final rssServiceProvider = Provider<RssService>((ref) => RssService());

final feedsProvider = StateNotifierProvider<FeedsNotifier, FeedsState>((ref) {
  return FeedsNotifier(ref.watch(rssServiceProvider));
});
