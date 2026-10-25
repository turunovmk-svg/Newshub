// lib/services/database_service.dart
// Сервис базы данных SQLite через sqflite
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'models/feed.dart';
import 'models/article.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;

  Database? _db;

  DatabaseService._internal();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDB();
    return _db!;
  }

  Future<Database> _initDB() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'newshub.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE feeds(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            title TEXT NOT NULL,
            url TEXT NOT NULL,
            category TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE articles(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            feedId INTEGER NOT NULL,
            title TEXT NOT NULL,
            description TEXT NOT NULL,
            content TEXT NOT NULL,
            link TEXT NOT NULL,
            pubDate TEXT NOT NULL,
            isRead INTEGER NOT NULL,
            isFavorite INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE INDEX idx_articles_feedId ON articles(feedId)
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        // Миграция не требуется
      },
    );
  }

  // CRUD для лент
  Future<List<Feed>> getFeeds() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('feeds');
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];
      return Feed(
        id: map['id'] as int,
        title: map['title'] as String,
        url: map['url'] as String,
        category: map['category'] as String,
      );
    });
  }

  Future<int> addFeed(Feed feed) async {
    final db = await database;
    return await db.insert('feeds', feed.toJson());
  }

  Future<int> deleteFeed(int id) async {
    final db = await database;
    return await db.delete('feeds', id = id);
  }

  // CRUD для статей
  Future<List<Article>> getArticlesByFeed(int feedId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'articles',
      where: 'feedId = ?',
      whereArgs: [feedId],
      orderBy: 'pubDate DESC',
    );
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];
      return Article(
        id: map['id'] as int,
        feedId: map['feedId'] as int,
        title: map['title'] as String,
        description: map['description'] as String,
        content: map['content'] as String,
        link: map['link'] as String,
        pubDate: DateTime.parse(map['pubDate'] as String),
        isRead: map['isRead'] as int == 1,
        isFavorite: map['isFavorite'] as int == 1,
      );
    });
  }

  Future<List<Article>> getUnreadArticles() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'articles',
      where: 'isRead = ?',
      whereArgs: [0],
      orderBy: 'pubDate DESC',
    );
    return List.generate(maps.length, (i) {
      final Map<String, dynamic> map = maps[i];
      return Article(
        id: map['id'] as int,
        feedId: map['feedId'] as int,
        title: map['title'] as String,
        description: map['description'] as String,
        content: map['content'] as String,
        link: map['link'] as String,
        pubDate: DateTime.parse(map['pubDate'] as String),
        isRead: map['isRead'] as int == 1,
        isFavorite: map['isFavorite'] as int == 1,
      );
    });
  }

  Future<int> insertArticle(Article article) async {
    final db = await database;
    return await db.insert('articles', article.toJson());
  }

  Future<int> updateArticle(Article article) async {
    final db = await database;
    return await db.update(
      'articles',
      article.toJson(),
      where: 'id = ?',
      whereArgs: [article.id],
    );
  }

  Future<int> deleteArticle(int id) async {
    final db = await database;
    return await db.delete('articles', id = id);
  }
}