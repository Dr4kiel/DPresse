class SearchResult {
  final String id;
  final String title;
  final String source;
  final String date;
  final String description;

  const SearchResult({
    required this.id,
    required this.title,
    required this.source,
    required this.date,
    required this.description,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'date': date,
    'description': description,
  };

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
    id: json['id'] as String,
    title: json['title'] as String,
    source: json['source'] as String,
    date: json['date'] as String,
    description: json['description'] as String,
  );
}
