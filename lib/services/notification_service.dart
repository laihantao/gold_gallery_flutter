import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/gold_alert.dart';

/// Wraps [FlutterLocalNotificationsPlugin] for gold price alerts.
///
/// Call [initialize] once from [main] before [runApp]. All other methods are
/// safe to call from any isolate after that.
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'gold_price_alerts';
  static const String _channelName = 'Gold Price Alerts';
  static const String _channelDesc =
      'Notifies when gold prices cross your set thresholds';

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    _channelId,
    _channelName,
    channelDescription: _channelDesc,
    importance: Importance.high,
    priority: Priority.high,
    enableLights: true,
    playSound: true,
  );

  static const NotificationDetails _details =
      NotificationDetails(android: _androidDetails);

  static Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(initSettings);

    // Create the high-importance channel on Android 8+.
    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDesc,
      importance: Importance.high,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Request POST_NOTIFICATIONS permission on Android 13+.
  /// Returns true if granted (or on older Android where it is implicit).
  static Future<bool> requestPermission() async {
    final granted = await _plugin
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        true;
    return granted;
  }

  /// Show an OS notification for a triggered [GoldAlert].
  static Future<void> showPriceAlert(
      GoldAlert alert, double currentPrice) async {
    final direction = alert.alertAbove ? 'reached' : 'dropped to';
    await _plugin.show(
      alert.id.hashCode & 0x7FFFFFFF,
      '${alert.shopName} Gold Alert',
      '${alert.shopName} ${alert.purity} $direction '
          'RM ${currentPrice.toStringAsFixed(2)} '
          '(target: ${alert.alertAbove ? '≥' : '≤'} '
          'RM ${alert.targetPrice.toStringAsFixed(2)})',
      _details,
    );
  }

  /// Show a test OS notification for the given brand and purity.
  /// Uses a fixed notification ID so repeated tests replace the previous one.
  static Future<void> showTestAlert({
    required String shopName,
    required String purity,
  }) async {
    await _plugin.show(
      0x00FFFF,
      '[TEST] $shopName Gold Alert',
      '$shopName $purity — this is a test notification from Pocket Gold. '
          'If you see this, notifications are working correctly!',
      _details,
    );
  }
}
