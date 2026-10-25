// lib/services/rss_parser.dart
// Сервис парсинга RSS-лент
import 'package:http/http.dart';
import 'package:xml/xml.dart';
import 'package:html/html.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/feed.dart';
import 'models/article.dart';
import 'database_service.dart';

class RssParserService {
  static final RssParserService _instance = RssParserService._internal();
  factory RssParserService() => _instance;
  RssParserService._internal();

  final DateFormat _dateFormat = DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz');

  // Fetch and parse RSS 2.0/Atom feed
  Future<void> fetchAndParse(Feed feed) async {
    final DatabaseService dbService = DatabaseService();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    
    try {
      final response = await http.get(Uri.parse(feed.url));
      
      if (response.statusCode == 200) {
        final document = XmlDocument.parse(response.body);
        final List<Article> articles = [];
        
        // Parse based on feed type (RSS vs Atom)
        if (response.body.contains('<rss') || response.body.contains('<RDF')) {
          articles.addAll(_parseRss(document));
        } else {
          articles.addAll(_parseAtom(document));
        }
        
        // Save articles and set last update time
        for (final article in articles) {
          final existingArticles = await dbService.getArticlesByFeed(feed.id);
          final exists = existingArticles.any((a) => a.link == article.link);
          if (!exists) {
            await dbService.insertArticle(article);
          }
        }
        
        await prefs.setString('last_update_${feed.id}', DateTime.now().toIso8601String());
      }
    } catch (e) {
      print('Error parsing feed ${feed.url}: $e');
      // Отмена действий при ошибке
    }
  }

  List<Article> _parseRss(XmlDocument document) {
    final List<Article> articles = [];
    final channel = document.findElements('channel').first;
    final feedId = _getFeedIdFromTitle(channel.findElements('title').first.value);
    
    final items = channel.findElements('item');
    for (final item in items) {
      final title = _getValue(item, 'title');
      final description = _getValue(item, 'description');
      final link = _getValue(item, 'link');
      final pubDate = _parseDate(_getValue(item, 'pubDate'));
      
      String content = description;
      final enclosures = item.findElements('enclosure');
      if (enclosures.isNotEmpty()) {
        final imageUrl = enclosures.first.getAttribute('url');
        if (imageUrl != null) {
          content = '<img src=\"$imageUrl\" alt=\"$title\" style=\"max-width: 100%;\">\n$content';
        }
      }
      
      articles.add(Article(
        id: 0,
        feedId: feedId,
        title: title,
        description: description,
        content: content,
        link: link,
        pubDate: pubDate,
        isRead: false,
        isFavorite: false,
      ));
    }
    return articles;
  }

  List<Article> _parseAtom(XmlDocument document) {
    final List<Article> articles = [];
    final feedId = _getFeedIdFromTitle(document.findElements('title').first.value);
    
    final entries = document.findElements('entry');
    for (final entry in entries) {
      final title = _getValue(entry, 'title');
      final content = _getValue(entry, 'summary') ?? _getValue(entry, 'content') ?? '';
      final link = _getValue(entry, 'link');
      final pubDate = _parseDate(_getValue(entry, 'updated') ?? _getValue(entry, 'published'));
      
      articles.add(Article(
        id: 0,
        feedId: feedId,
        title: title,
        description: content,
        content: content,
        link: link,
        pubDate: pubDate,
        isRead: false,
        isFavorite: false,
      ));
    }
    return articles;
  }

  String _getValue(XmlElement parent, String tag) {
    final element = parent.findElements(tag).firstOrNull;
    return element?.value ?? '';
  }

  int _getFeedIdFromTitle(String title) {
    // В реальном приложении здесь будет логика поиска или создания feedId
    return title.hashCode.abs() % 10000;
  }

  DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return DateTime.now();
    }
    try {
      return _dateFormat.parse(dateString);
    } catch (e) {
      return DateTime.now();
    }
  }

  // Parse HTML content for Reader Mode
  String parseHtmlForReaderMode(String htmlContent) {
    try {
      final document = HtmlDocument.html(htmlContent);
      final body = document.body;
      if (body == null) return htmlContent;
      
      // Remove unwanted elements
      final unwantedTags = ['script', 'style', 'nav', 'header', 'footer', 'aside'];
      for (final tag in unwantedTags) {
        body.querySelectorAll(tag).forEach((element) => element.remove());
      }
      
      return body.outerHtml;
    } catch (e) {
      return htmlContent;
    }
  }
}