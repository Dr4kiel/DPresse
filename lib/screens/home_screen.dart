import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:string_similarity/string_similarity.dart';
import '../core/constants.dart';
import '../models/feed_item.dart';
import '../providers/feeds_provider.dart';
import '../providers/search_provider.dart';
import '../widgets/feed_section.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Load feeds on first build
    Future.microtask(() {
      ref.read(feedsProvider.notifier).refreshFeeds();
    });
  }

  Future<void> _onFeedItemTap(FeedItem item) async {
    if (!mounted) return;

    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Recherche: ${item.title}'),
        duration: const Duration(seconds: 1),
      ),
    );

    // Search for article in Europresse by title
    final searchNotifier = ref.read(searchProvider.notifier);
    searchNotifier.setSearchInTitle(true);
    searchNotifier.setDateRange(AppConstants.dateRangeWeek);
    await searchNotifier.search(item.title);

    if (!mounted) return;

    final searchState = ref.read(searchProvider);

    // Show actual error if search failed
    if (searchState.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${searchState.error}'),
          duration: const Duration(seconds: 4),
        ),
      );
      return;
    }

    if (searchState.results.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucun article trouvé sur Europresse')),
      );
      return;
    }

    // Sort by Levenshtein distance (best match first)
    final sorted = [...searchState.results];
    sorted.sort((a, b) {
      final simA = StringSimilarity.compareTwoStrings(
        item.title.toLowerCase(),
        a.title.toLowerCase(),
      );
      final simB = StringSimilarity.compareTwoStrings(
        item.title.toLowerCase(),
        b.title.toLowerCase(),
      );
      return simB.compareTo(simA);
    });

    // Navigate to the best match
    if (mounted) {
      final bestMatch = sorted.first;
      context.push('/article/${Uri.encodeComponent(bestMatch.id)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final feedsState = ref.watch(feedsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(feedsProvider.notifier).refreshFeeds(),
        child: feedsState.isLoading && feedsState.feedItems.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : feedsState.feedItems.isEmpty
                ? _buildEmptyState(theme)
                : ListView(
                    children: [
                      for (final feed in feedsState.feeds.where((f) => f.enabled))
                        if (feedsState.feedItems.containsKey(feed.id))
                          FeedSection(
                            title: feed.name,
                            items: feedsState.feedItems[feed.id]!,
                            onItemTap: _onFeedItemTap,
                          ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rss_feed,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucun flux RSS',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tirez vers le bas pour rafraîchir',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
