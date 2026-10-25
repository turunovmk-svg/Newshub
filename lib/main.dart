// lib/main.dart
// Точка входа приложения. Инициализация БД, уведомлений, запуск HomeScreen
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'screens/home_screen.dart';
import 'services/database_service.dart';
import 'services/notification_service.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NewsHub',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomeScreenWrapper(),
    );
  }
}

class HomeScreenWrapper extends StatefulWidget {
  const HomeScreenWrapper({super.key});

  @override
  State<HomeScreenWrapper> createState() => _HomeScreenWrapperState();
}

class _HomeScreenWrapperState extends State<HomeScreenWrapper> {
  bool _isInitialized = false;
  bool _initError = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await NotificationService().init();
      await NotificationService().requestPermissions();
      await DatabaseService().database;
      if (mounted) {
        setState(() => _isInitialized = true);
      }
    } catch (e) {
      print('Initialization error: $e');
      if (mounted) setState(() => _initError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError) {
      return Scaffold(
        body: Center(child: Text('Ошибка инициализации приложения')),
      );
    }
    if (!_isInitialized) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return const HomeScreen();
  }
}