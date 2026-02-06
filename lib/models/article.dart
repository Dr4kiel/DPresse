class Article {
  final String id;
  final String title;
  final String source;
  final String date;
  final String description;
  final String html;

  const Article({
    required this.id,
    required this.title,
    required this.source,
    required this.date,
    required this.description,
    required this.html,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'source': source,
    'date': date,
    'description': description,
    'html': html,
  };

  factory Article.fromJson(Map<String, dynamic> json) => Article(
    id: json['id'] as String,
    title: json['title'] as String,
    source: json['source'] as String,
    date: json['date'] as String,
    description: json['description'] as String,
    html: json['html'] as String,
  );
}
