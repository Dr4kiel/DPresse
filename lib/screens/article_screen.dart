import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/article.dart';
import '../providers/article_provider.dart';
import '../providers/bookmarks_provider.dart';
import '../providers/settings_provider.dart';

class ArticleScreen extends ConsumerStatefulWidget {
  final String articleId;

  const ArticleScreen({super.key, required this.articleId});

  @override
  ConsumerState<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends ConsumerState<ArticleScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(articleProvider.notifier).loadArticle(widget.articleId);
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final articleState = ref.watch(articleProvider);
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        actions: [
          if (articleState.article != null)
            _BookmarkButton(article: articleState.article!),
        ],
      ),
      body: _buildBody(articleState, settings, theme),
    );
  }

  Widget _buildBody(
    ArticleState articleState,
    SettingsState settings,
    ThemeData theme,
  ) {
    if (articleState.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (articleState.error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text('Impossible de charger l\'article',
                style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                ref.read(articleProvider.notifier).loadArticle(widget.articleId);
              },
              child: const Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    final article = articleState.article;
    if (article == null) {
      return const Center(child: Text('Article introuvable'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                article.title,
                style: GoogleFonts.sourceSerif4(
                  fontSize: settings.fontSize + 8,
                  fontWeight: FontWeight.bold,
                  height: 1.3,
                ),
              ),
            ),
          if (article.source.isNotEmpty || article.date.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                [article.source, article.date]
                    .where((s) => s.isNotEmpty)
                    .join(' - '),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const Divider(),
          const SizedBox(height: 8),
          Html(
            data: article.html,
            style: {
              'body': Style(
                fontFamily: GoogleFonts.sourceSerif4().fontFamily,
                fontSize: FontSize(settings.fontSize),
                lineHeight: const LineHeight(1.6),
              ),
              'p': Style(
                margin: Margins.only(bottom: 12),
              ),
              'img': Style(
                width: Width(MediaQuery.of(context).size.width - 32),
              ),
            },
          ),
        ],
      ),
    );
  }
}

class _BookmarkButton extends ConsumerWidget {
  final Article article;

  const _BookmarkButton({required this.article});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookmarks = ref.watch(bookmarksProvider);
    final isBookmarked = bookmarks.any((a) => a.id == article.id);

    return IconButton(
      icon: Icon(isBookmarked ? Icons.bookmark : Icons.bookmark_outline),
      onPressed: () {
        if (isBookmarked) {
          ref.read(bookmarksProvider.notifier).removeBookmark(article.id);
        } else {
          ref.read(bookmarksProvider.notifier).addBookmark(article);
        }
      },
    );
  }
}
