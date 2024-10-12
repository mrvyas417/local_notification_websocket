import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:local_notification_app/web_shocket_manger.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'WebSocket Notifications POC',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const NotificationHomePage(),
    );
  }
}

class NotificationHomePage extends StatefulWidget {
  const NotificationHomePage({Key? key}) : super(key: key);

  @override
  _NotificationHomePageState createState() => _NotificationHomePageState();
}

class _NotificationHomePageState extends State<NotificationHomePage> {
  late FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;
  late WebSocketChannel channel;

  @override
  void initState() {
    super.initState();
    // WebSocketManager.startWebSocketService();
    // Initialize local notifications
    flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);
    flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Request notification permission
    requestNotificationPermission();

    // Connect to WebSocket Server
    connectToWebSocket();
  }

  // Function to request notification permission
  Future<void> requestNotificationPermission() async {
    if (await Permission.notification.isGranted) {
      log("Notification permission already granted");
    } else {
      PermissionStatus status = await Permission.notification.request();
      if (status.isGranted) {
        log("Notification permission granted");
      } else if (status.isDenied) {
        log("Notification permission denied");
      } else if (status.isPermanentlyDenied) {
        openAppSettings(); // Open app settings to manually grant permission
      }
    }
  }

  void connectToWebSocket() {
    // Replace with your WebSocket server URL
    channel = WebSocketChannel.connect(Uri.parse('ws://10.0.2.2:8080'));

    // Listen for WebSocket messages
    channel.stream.listen((message) {
      if (kDebugMode) {
        print("New message: $message");
      }
      dynamic msg = jsonDecode(message);
      showNotification(msg["message"]);
    });
  }

  Future<void> showNotification(String message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'channel_id',
      'channel_name',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'New WebSocket Message',
      message, // Body
      platformChannelSpecifics,
    );
  }

  @override
  void dispose() {
    channel.sink.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('WebSocket Notifications POC'),
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                // You can send a message to WebSocket for testing if needed
                channel.sink.add("Test message from web shocket notifcation!");
              },
              child: const Text('Send Test Message'),
            ),
          ),
          Center(
            child: ElevatedButton(
              onPressed: () {
                try {
                  WebSocketManager.startWebSocketService();
                } catch (e) {
                  log("getting error while enabling method channel $e");
                }
              },
              child: const Text('Start Method Channel Service '),
            ),
          ),
        ],
      ),
    );
  }
}
