import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushNotificationsService {
  static FirebaseMessaging messaging = FirebaseMessaging.instance;
  static String? token;
  static final StreamController<String> _messageStream =
      StreamController<String>.broadcast();

  static Stream<String> get messageStream => _messageStream.stream;

  static const AndroidNotificationChannel channel = AndroidNotificationChannel(
    'high_importance_channel', // id
    'High Importance Notifications', // title
    description:
        "This channel is used for important notifications.", // description
    importance: Importance.max,
  );

  static final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> _backgroundHandler(RemoteMessage message) async {
    // print('_backgroundHandler: ${message.messageId}');
    _messageStream.add(message.notification?.title ?? 'Notification');
  }

  static Future<void> _onMessageHandler(RemoteMessage message) async {
    // print('_onMessageHandler: ${message.messageId}');
    _messageStream.add(message.notification?.title ?? 'Notification');

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    RemoteNotification? notification = message.notification;
    String iconName = const AndroidInitializationSettings('@mipmap/ic_launcher')
        .defaultIcon
        .toString();

    // Si `onMessage` es activado con una notificación, construimos nuestra propia
    // notificación local para mostrar a los usuarios, usando el canal creado.
    if (notification != null) {
      flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(channel.id, channel.name,
                channelDescription: channel.description, icon: iconName),
          ));
    }
  }

  static Future<void> _onMessageOpenHandler(RemoteMessage message) async {
    // print('_onMessageOpenHandler: ${message.messageId}');
    _messageStream.add(message.notification?.title ?? 'Notification');
  }

  static Future<void> initializeApp() async {
    await Firebase.initializeApp();

    token = await FirebaseMessaging.instance.getToken();
    FirebaseMessaging.onBackgroundMessage(_backgroundHandler);
    FirebaseMessaging.onMessage.listen(_onMessageHandler);
    FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpenHandler);
    print('token: $token');
  }

  static closeStreams() {
    _messageStream.close();
  }
}
