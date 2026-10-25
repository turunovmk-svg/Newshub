// lib/screens/article_screen.dart
// Экран чтения статьи: Reader Mode, кнопки "Избранное" и "Открыть в браузере"
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/article.dart';
import '../services/database_service.dart';

class ArticleScreen extends StatefulWidget {
  final Article article;
  const ArticleScreen({super.key, required this.article});

  @override
  State<ArticleScreen> createState() => _ArticleScreenState();
}

class _ArticleScreenState extends State<ArticleScreen> {
  late final DatabaseService _dbService;
  late Article _article;
  final WebViewController _controller = WebViewController();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbService = DatabaseService();
    _article = widget.article;
    _initWebView();
  }

  void _initWebView() {
    _controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _isLoading = false);
          },
        ),
      )
      ..loadHtmlString(_buildHtmlContent(_article.content));
  }

  String _buildHtmlContent(String content) {
    return '''
      <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <style>
            body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; 
                   line-height: 1.6; color: #1a1a1a; padding: 16px; font-size: 16px; }
            h1, h2, h3 { color: #2c3e50; line-height: 1.3; }
            a { color: #3498db; text-decoration: none; }
            a:hover { text-decoration: underline; }
            img { max-width: 100%; height: auto; border-radius: 8px; }
            blockquote { border-left: 4px solid #3498db; padding-left: 16px; color: #555; margin: 16px 0; }
            code { background: #f4f4f4; padding: 2px 6px; border-radius: 4px; font-family: monospace; }
            pre { background: #2c3e50; color: #ecf0f1; padding: 16px; border-radius: 8px; overflow-x: auto; }
            .article-header { border-bottom: 1px solid #eee; padding-bottom: 16px; margin-bottom: 16px; }
            .article-meta { color: #777; font-size: 14px; }
          </style>
        </head>
        <body>
          <div class="article-header">
            <h1>${_article.title}</h1>
            <div class="article-meta">${_formatDate(_article.pubDate)}</div>
          </div>
          <div>${content}</div>
        </body>
      </html>
    ''';
  }

  String _formatDate(DateTime date) {
    try {
      return DateFormat('EEEE, MMMM dd, yyyy • HH:mm').format(date);
    } catch (_) {
      return date.toString();
    }
  }

  void _toggleFavorite() async {
    final updated = Article(
      id: _article.id,
      feedId: _article.feedId,
      title: _article.title,
      description: _article.description,
      content: _article.content,
      link: _article.link,
      pubDate: _article.pubDate,
      isRead: _article.isRead,
      isFavorite: !_article.isFavorite,
    );
    await _dbService.updateArticle(updated);
    if (mounted) setState(() => _article = updated);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(_article.isFavorite ? 'Убрано из избранного' : 'Добавлено в избранное')),
    );
  }

  void _openInBrowser() async {
    final Uri url = Uri.parse(_article.link);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  void _markAsRead() async {
    final updated = Article(
      id: _article.id,
      feedId: _article.feedId,
      title: _article.title,
      description: _article.description,
      content: _article.content,
      link: _article.link,
      pubDate: _article.pubDate,
      isRead: true,
      isFavorite: _article.isFavorite,
    );
    await _dbService.updateArticle(updated);
    if (mounted) setState(() => _article = updated);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Читать'),
        actions: [
          IconButton(
            icon: Icon(
              _article.isFavorite ? Icons.bookmark : Icons.bookmark_border,
              color: _article.isFavorite ? Colors.amber : null,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'Избранное',
          ),
          IconButton(
            icon: const Icon(Icons.open_in_new),
            onPressed: _openInBrowser,
            tooltip: 'Открыть в браузере',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {},
            tooltip: 'Поделиться',
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}