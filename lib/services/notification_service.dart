// lib/services/notification_service.dart
// Уведомления через flutter_local_notifications
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'models/article.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> init() async {
    final androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    final initSettings = InitializationSettings(
      android: androidSettings,
    );
    
    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap
      },
    );
  }

  // Request permissions
  Future<bool> requestPermissions() async {
    final notifStatus = await Permission.postNotifications.status;
    if (notifStatus.isDenied) {
      final result = await Permission.postNotifications.request();
      return result.isGranted;
    }
    return notifStatus.isGranted;
  }

  // Show notification for new article
  Future<void> showNewArticleNotification(Article article) async {
    await requestPermissions();
    
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'new_article_channel',
      'Новые статьи',
      importance: Importance.high,
      description: 'Уведомления о новых статьях в лентах',
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'new_article_channel',
      'Новые статьи',
      channelDescription: 'Уведомления о новых статьях в лентах',
      importance: Importance.high,
      priority: Priority.high,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.show(
      0,
      'Новая статья: ${article.title}',
      article.description,
      details,
    );
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  // Schedule notification for boot completed
  Future<void> scheduleBootNotification(int articleId, String title, String description) async {
    await requestPermissions();
    
    final AndroidNotificationChannel channel = AndroidNotificationChannel(
      'boot_channel',
      'Boot Notifications',
      importance: Importance.high,
    );

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'boot_channel',
      'Boot Notifications',
      importance: Importance.high,
    );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );

    await _notifications.zonedSchedule(
      1,
      'Новая статья: $title',
      description,
      DateTime.now(),
      details,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
    );
  }
}