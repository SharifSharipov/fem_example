import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await NotificationService.instance.setupFlutterNotifications();
  await NotificationService.instance.showNotifications(message);
  debugPrint('Handling a background message ${message.messageId}');
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _isFlutterNotificationEnabled = false;
  final FlutterLocalNotificationsPlugin _localNotification =
      FlutterLocalNotificationsPlugin();
  Future<void> initialize() async {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    //request permission
    await _requestPermission();
    //setup message handlers
    await _setupMessageHandlers();
    // fcm token
    final token= await _messaging.getToken();
    debugPrint('fcm Token: $token');
    
  }

  Future<void> _requestPermission() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );
    debugPrint('User granted permission: ${settings.authorizationStatus}');
  }

  Future<void> setupFlutterNotifications() async {
    if (_isFlutterNotificationEnabled) {
      return;
    }

    // Android setup
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'high_importance_channel',
      'High Importance Notification',
      importance: Importance.high,
      description: 'High Importance Notification',
    );

    await _localNotification
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS setup
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotification.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint("Notification clicked: ${response.payload}");
      },
    );

    _isFlutterNotificationEnabled = true;

    await _setupMessageHandlers();
  }

  Future<void> showNotifications(RemoteMessage message) async {
    RemoteNotification? notification = message.notification;

    if (notification != null) {
      await _localNotification.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            "high_importance_channel",
            "High Importance Channel",
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            channelDescription:
                "This channel is used for important notifications",
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data.toString(),
      );
    }
  }

  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    debugPrint('Got a message whilst in the background!');
    debugPrint('Message data: ${message.data}');

    if (message.data['type'] == 'chat') {
      // TODO: Chat ekranga o'tish uchun kod qo'shing
    }
  }

  Future<void> _setupMessageHandlers() async {
    // Foreground message
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      showNotifications(message);
      debugPrint('Got a message whilst in the foreground!');
      debugPrint('Message data: ${message.data}');
    });

    // Background message
    FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

    // Open app from notification
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      _handleBackgroundMessage(initialMessage);
    }
    /*   FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Got a message that caused the app to open from a notification!');
      debugPrint('Message data: ${message.data}');
    });*/
  }
}
