class FeedItem {
  final String title;
  final String link;
  final String description;
  final String source;
  final DateTime? pubDate;

  const FeedItem({
    required this.title,
    required this.link,
    required this.description,
    required this.source,
    this.pubDate,
  });
}
