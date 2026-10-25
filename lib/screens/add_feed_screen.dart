// lib/screens/add_feed_screen.dart
// Форма для добавления RSS-ленты
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/feed.dart';
import '../services/database_service.dart';

class AddFeedScreen extends StatefulWidget {
  const AddFeedScreen({super.key});

  @override
  State<AddFeedScreen> createState() => _AddFeedScreenState();
}

class _AddFeedScreenState extends State<AddFeedScreen> {
  final _formKey = GlobalKey<FormState>();
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  String _selectedCategory = 'Новости';
  final List<String> _categories = [
    'Новости',
    'Технологии',
    'Спорт',
    'Наука',
    'Бизнес',
    'Политика',
    'Развлечения',
    'Другое',
  ];

  final DatabaseService _dbService = DatabaseService();

  void _addFeed() async {
    if (_formKey.currentState!.validate()) {
      final feed = Feed(
        id: 0,
        title: _titleController.text,
        url: _urlController.text,
        category: _selectedCategory,
      );

      try {
        await _dbService.addFeed(feed);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка добавления: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Добавить RSS-ленту'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'RSS-лента',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  items: _categories
                      .map((cat) => DropdownMenuItem(
                            value: cat,
                            child: Text(cat),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedCategory = value);
                    }
                  },
                  decoration: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'URL RSS-ленты',
                      style: Theme.of(context).inputDecorationTheme.labelStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _urlController,
                  decoration: const BoxDecoration(
                    border: UnderlineTabsBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Название',
                      style: Theme.of(context).inputDecorationTheme.labelStyle,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextField(
                  controller: _titleController,
                  decoration: const BoxDecoration(
                    border: UnderlineTabsBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addFeed,
                      child: const Text('Добавить'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}