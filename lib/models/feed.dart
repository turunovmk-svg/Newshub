// lib/models/feed.dart
// Модель RSS-ленты: id, title, url, category
class Feed {
  final int id;
  final String title;
  final String url;
  final String category;

  Feed({required this.id, required this.title, required this.url, required this.category});

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'url': url,
      'category': category
    };
  }

  factory Feed.fromJson(Map<String, dynamic> json) {
    return Feed(
      id: json['id'] as int,
      title: json['title'] as String,
      url: json['url'] as String,
      category: json['category'] as String
    );
  }
}
