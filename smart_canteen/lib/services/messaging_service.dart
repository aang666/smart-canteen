import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/app_constants.dart';

// Background message handler (Top-level function wajib di luar class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('FCM Background message diterima: ${message.messageId}');
}

class MessagingService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _orderChannel = AndroidNotificationChannel(
    'smart_canteen_orders',
    'Notifikasi Pesanan Kantin',
    description: 'Pemberitahuan pesanan masuk dan pesanan siap diambil',
    importance: Importance.high,
    playSound: true,
  );

  // Inisialisasi plugin notifikasi lokal & listener FCM
  Future<void> initialize({void Function(Map<String, dynamic> data)? onNotificationTap}) async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && onNotificationTap != null) {
          // Navigasi saat notifikasi foreground di-tap
        }
      },
    );

    // Buat notification channel dengan prioritas tinggi pada Android
    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_orderChannel);

    // 1. Tangani pesan saat aplikasi sedang aktif di FOREGROUND
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('FCM Foreground message: ${message.notification?.title}');
      _showForegroundNotification(message);
    });

    // 2. Tangani saat notifikasi di-tap saat aplikasi di BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('FCM Opened from background: ${message.data}');
      if (onNotificationTap != null) {
        onNotificationTap(message.data);
      }
    });

    // 3. Tangani saat notifikasi di-tap saat aplikasi dalam kondisi TERMINATED (Mati)
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null && onNotificationTap != null) {
      onNotificationTap(initialMessage.data);
    }
  }

  // Meminta izin notifikasi runtime (Android 13+ dan iOS) serta simpan token
  Future<void> registerDeviceToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Meminta izin runtime (Wajib untuk Android 13+)
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      debugPrint('Izin notifikasi ditolak oleh pengguna.');
      return;
    }

    // Ambil token perangkat saat ini
    final token = await _messaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(user.uid, token);
    }

    // Dengarkan jika ada token refresh dari Google Play Services
    _messaging.onTokenRefresh.listen((newToken) {
      _saveTokenToFirestore(user.uid, newToken);
    });
  }

  // Simpan token ke subkoleksi users/{uid}/devices/current
  Future<void> _saveTokenToFirestore(String uid, String token) async {
    try {
      await _db
          .collection(AppConstants.colUsers)
          .doc(uid)
          .collection(AppConstants.colDevices)
          .doc('current')
          .set({
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'other',
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      debugPrint('FCM Token tersimpan di users/$uid/devices/current');
    } catch (e) {
      debugPrint('Gagal menyimpan token FCM ke Firestore: $e');
    }
  }

  // Tampilkan notifikasi visual lokal saat aplikasi di Foreground
  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final title = notification?.title ?? 'Smart Canteen';
    final body = notification?.body ?? 'Ada pembaruan status pesanan.';

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'smart_canteen_orders',
          'Notifikasi Pesanan Kantin',
          channelDescription: 'Pemberitahuan pesanan masuk dan pesanan siap diambil',
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          playSound: true,
        ),
      ),
      payload: message.data.toString(),
    );
  }
}
