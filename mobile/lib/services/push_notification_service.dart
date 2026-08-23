import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../core/constants/api_constants.dart';
import '../providers/auth_provider.dart';

class PushNotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  String? _fcmToken;
  bool _isInitialized = false;

  // Initialize push notifications
  Future<void> initialize(BuildContext context) async {
    if (_isInitialized) return;
    
    try {
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Request permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
        criticalAlert: true,
        carPlay: true,
        announcement: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        print('User granted permission');

        // Get FCM token
        _fcmToken = await _firebaseMessaging.getToken();
        print('FCM Token: $_fcmToken');

        // Store token on server
        if (_fcmToken != null) {
          await _storeFcmToken(context, _fcmToken!);
        }

        // Listen for token refresh
        _firebaseMessaging.onTokenRefresh.listen((token) {
          _fcmToken = token;
          _storeFcmToken(context, token);
        });

        // Handle foreground messages
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          _handleForegroundMessage(message);
        });

        // Handle background messages
        FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
          _handleBackgroundMessage(message);
        });

        // Handle when app is opened from terminated state
        RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
        if (initialMessage != null) {
          _handleBackgroundMessage(initialMessage);
        }
        
        _isInitialized = true;
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        print('User granted provisional permission');
      } else {
        print('User declined or has not accepted permission');
      }
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }

  // Initialize flutter_local_notifications
  Future<void> _initializeLocalNotifications() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final IOSInitializationSettings initializationSettingsIOS =
        IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification: (int id, String? title, String? body, String? payload) async {
        // Handle iOS notification tap
        _onNotificationTapped(payload);
      },
    );

    // macOS initialization
    final MacOSInitializationSettings initializationSettingsMacOS =
        MacOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    // Linux initialization
    final LinuxInitializationSettings initializationSettingsLinux =
        const LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      macOS: initializationSettingsMacOS,
      linux: initializationSettingsLinux,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onSelectNotification: (String? payload) {
        _onNotificationTapped(payload);
      },
    );

    // Create notification channels for Android
    await _createNotificationChannels();
  }

  // Create Android notification channels
  Future<void> _createNotificationChannels() async {
    if (Platform.isAndroid) {
      const AndroidNotificationChannel bookingChannel = AndroidNotificationChannel(
        'booking_channel',
        'Booking Notifications',
        description: 'Notifications related to your bookings',
        importance: Importance.high,
      );

      const AndroidNotificationChannel paymentChannel = AndroidNotificationChannel(
        'payment_channel',
        'Payment Notifications',
        description: 'Notifications related to payments',
        importance: Importance.high,
      );

      const AndroidNotificationChannel generalChannel = AndroidNotificationChannel(
        'general_channel',
        'General Notifications',
        description: 'General notifications from StudioBook',
        importance: Importance.defaultImportance,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(bookingChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(paymentChannel);

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(generalChannel);
    }
  }

  // Handle notification tap
  void _onNotificationTapped(String? payload) {
    if (payload == null) return;
    
    try {
      final data = jsonDecode(payload);
      final type = data['type'];
      
      // Navigate based on notification type
      switch (type) {
        case 'booking_confirmed':
        case 'booking_reminder':
        case 'booking_cancelled':
          // Navigate to booking detail or list
          print('Navigate to booking: ${data['booking_id']}');
          break;
        case 'payment_reminder':
        case 'payment_success':
          // Navigate to payment page
          print('Navigate to payment: ${data['payment_code']}');
          break;
        case 'new_booking':
          // Navigate to owner bookings
          print('Navigate to owner bookings');
          break;
        case 'band_invitation':
          // Navigate to band detail
          print('Navigate to band: ${data['band_id']}');
          break;
        default:
          print('Unknown notification type: $type');
      }
    } catch (e) {
      print('Error parsing notification payload: $e');
    }
  }

  // Store FCM token on server
  Future<void> _storeFcmToken(BuildContext context, String token) async {
    try {
      final authProvider = context.read<AuthProvider>();
      final userToken = authProvider.token;

      if (userToken == null) {
        print('No auth token available');
        return;
      }

      final response = await http.post(
        Uri.parse('${ApiConstants.apiUrl}${ApiConstants.notificationsFcmToken}'),
        headers: {
          'Authorization': 'Bearer $userToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        print('FCM token stored successfully');
      } else {
        print('Failed to store FCM token: ${response.body}');
      }
    } catch (e) {
      print('Error storing FCM token: $e');
    }
  }

  // Handle foreground messages
  void _handleForegroundMessage(RemoteMessage message) {
    print('Received foreground message: ${message.messageId}');
    
    final notification = message.notification;
    final data = message.data;

    if (notification != null) {
      // Show local notification
      _showLocalNotification(
        title: notification.title ?? 'StudioBook',
        body: notification.body ?? '',
        data: data,
      );
    }

    // Handle data message
    _handleNotificationData(data);
  }

  // Handle background messages
  void _handleBackgroundMessage(RemoteMessage message) {
    print('Handling background message: ${message.messageId}');
    
    final data = message.data;
    _handleNotificationData(data);
  }

  // Handle notification data
  void _handleNotificationData(Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'booking_confirmed':
        print('Navigate to booking detail');
        break;
      case 'booking_reminder':
        print('Navigate to booking detail');
        break;
      case 'payment_reminder':
        print('Navigate to payment page');
        break;
      case 'booking_cancelled':
        print('Navigate to bookings list');
        break;
      case 'new_booking':
        print('Navigate to owner bookings');
        break;
      case 'band_invitation':
        print('Navigate to band detail');
        break;
      default:
        print('Unknown notification type: $type');
    }
  }

  // Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
  }) async {
    // Determine notification channel based on type
    String channelId = 'general_channel';
    String channelName = 'General Notifications';
    
    final type = data['type'];
    if (type != null) {
      if (type.toString().contains('booking')) {
        channelId = 'booking_channel';
        channelName = 'Booking Notifications';
      } else if (type.toString().contains('payment')) {
        channelId = 'payment_channel';
        channelName = 'Payment Notifications';
      }
    }

    // Android notification details
    AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      channelId,
      channelName,
      icon: '@mipmap/ic_launcher',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      styleInformation: BigTextStyleInformation(body),
    );

    // iOS notification details
    IOSNotificationDetails iOSPlatformChannelSpecifics =
        const IOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // macOS notification details
    MacOSNotificationDetails macOSPlatformChannelSpecifics =
        const MacOSNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
      macOS: macOSPlatformChannelSpecifics,
    );

    // Generate unique notification ID
    final int notificationId = DateTime.now().millisecondsSinceEpoch.remainder(100000);

    await _localNotifications.show(
      notificationId,
      title,
      body,
      platformChannelSpecifics,
      payload: jsonEncode(data),
    );
  }

  // Get current FCM token
  String? get fcmToken => _fcmToken;

  // Check if notifications are enabled
  bool get isInitialized => _isInitialized;

  // Subscribe to topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }

  // Unsubscribe from topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }

  // Delete FCM token
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      print('FCM token deleted');
    } catch (e) {
      print('Error deleting FCM token: $e');
    }
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  // Cancel specific notification
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _localNotifications.pendingNotificationRequests();
  }
}

// Top-level function for background message handling
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Background message received: ${message.messageId}');
  
  // Handle background message
  final data = message.data;
  final type = data['type'];
  
  print('Background notification type: $type');
}

// Register background handler
void initializeBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
}
