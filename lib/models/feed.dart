class Feed {
  final String id;
  final String name;
  final String url;
  final bool enabled;

  const Feed({
    required this.id,
    required this.name,
    required this.url,
    this.enabled = true,
  });

  Feed copyWith({
    String? id,
    String? name,
    String? url,
    bool? enabled,
  }) => Feed(
    id: id ?? this.id,
    name: name ?? this.name,
    url: url ?? this.url,
    enabled: enabled ?? this.enabled,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'url': url,
    'enabled': enabled,
  };

  factory Feed.fromJson(Map<String, dynamic> json) => Feed(
    id: json['id'] as String,
    name: json['name'] as String,
    url: json['url'] as String,
    enabled: json['enabled'] as bool? ?? true,
  );
}
