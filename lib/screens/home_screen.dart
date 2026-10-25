// lib/screens/home_screen.dart
// Главный экран приложения: список статей с Pull-to-refresh
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/article.dart';
import '../models/feed.dart';
import '../services/database_service.dart';
import '../services/rss_parser.dart';
import 'article_screen.dart';
import 'add_feed_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final DateFormat _dateFormat = DateFormat('EEE, MMM dd');

  List<Article> _articles = [];
  List<Feed> _feeds = [];
  List<Feed> _allFeeds = [];
  bool _isLoading = false;
  final DatabaseService _dbService = DatabaseService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadArticles();
    });
  }

  Future<void> _loadArticles() async {
    setState(() => _isLoading = true);
    try {
      final feeds = await _dbService.getFeeds();
      _feeds = feeds;
      _allFeeds = List.from(feeds);
      final articles = await _dbService.getUnreadArticles();
      _articles = articles;
    } catch (e) {
      print('Error loading articles: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshArticles() async {
    setState(() => _isLoading = true);
    for (final feed in _allFeeds) {
      await RssParserService().fetchAndParse(feed);
    }
    await _loadArticles();
    if (mounted) setState(() {});
    setState(() => _isLoading = false);
  }

  void _showAddFeedDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddFeedScreen()),
    ).then((_) {
      _loadArticles();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('NewsHub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _showAddFeedDialog,
            tooltip: 'Добавить канал',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshArticles,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildArticleList(),
      ),
    );
  }

  Widget _buildArticleList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: _articles.length + 1,
            itemBuilder: (_, index) {
              if (index == _articles.length) {
                return const SizedBox(height: 8);
              }
              return _buildArticleCard(_articles[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(Article article) {
    final now = DateTime.now();
    final pubDate = _formatDate(article.pubDate);
    final feed = _feeds.firstWhere((f) => f.id == article.feedId, orElse: () => null);
    final isRecent = now.difference(article.pubDate).inMinutes < 30;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: Icon(
          article.isRead ? Icons.schedule : Icons.article,
          color: article.isRead ? Colors.grey : Colors.blue,
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                article.title,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!article.isRead)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 6,
                  backgroundColor: Colors.green,
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${_formatTime(pubDate)} • ${feed?.category ?? ''}',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  article.description,
                  style: const TextStyle(fontSize: 14, color: Colors.grey[700]),
                  maxLines: 5,
                  overflow: TextOverflow.ellipsis,
                ),
                if (feed != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      feed.title,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: Icon(
                  article.isFavorite ? Icons.favorite : Icons.favorite_border,
                  size: 20,
                ),
                color: article.isFavorite ? Colors.red : Colors.transparent,
                onPressed: () {
                  final updated = Article(
                    id: article.id,
                    feedId: article.feedId,
                    title: article.title,
                    description: article.description,
                    content: article.content,
                    link: article.link,
                    pubDate: article.pubDate,
                    isRead: article.isRead,
                    isFavorite: !article.isFavorite,
                  );
                  _updateArticle(updated);
                },
              ),
              IconButton(
                icon: const Icon(Icons.open_in_browser, size: 20),
                onPressed: () {},
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.delete, size: 18),
                label: const Text('Удалить'),
                onPressed: () async {
                  await _dbService.deleteArticle(article.id);
                  _loadArticles();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    try {
      return _dateFormat.format(date);
    } catch (_) {
      return date.toString();
    }
  }

  String _formatTime(DateTime date) {
    final format = DateFormat('HH:mm');
    try {
      return format.format(date);
    } catch (_) {
      return date.toString();
    }
  }

  void _updateArticle(Article updated) async {
    await _dbService.updateArticle(updated);
    setState(() {
      _articles.removeWhere((a) => a.id == updated.id);
      _articles.insert(0, updated);
      _articles = List.from(_articles);
    });
  }
}