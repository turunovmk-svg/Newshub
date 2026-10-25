// lib/models/article.dart
// Модель статьи: id, feedId, title, description, content, link, pubDate, isRead, isFavorite
class Article {
  final int id;
  final int feedId;
  final String title;
  final String description;
  final String content;
  final String link;
  final DateTime pubDate;
  final bool isRead;
  final bool isFavorite;

  Article({
    required this.id,
    required this.feedId,
    required this.title,
    required this.description,
    required this.content,
    required this.link,
    required this.pubDate,
    required this.isRead,
    required this.isFavorite,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'feedId': feedId,
      'title': title,
      'description': description,
      'content': content,
      'link': link,
      'pubDate': pubDate.toIso8601String(),
      'isRead': isRead,
      'isFavorite': isFavorite,
    };
  }

  factory Article.fromJson(Map<String, dynamic> json) {
    return Article(
      id: json['id'] as int,
      feedId: json['feedId'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      content: json['content'] as String,
      link: json['link'] as String,
      pubDate: DateTime.parse(json['pubDate'] as String),
      isRead: json['isRead'] as bool,
      isFavorite: json['isFavorite'] as bool,
    );
  }
}