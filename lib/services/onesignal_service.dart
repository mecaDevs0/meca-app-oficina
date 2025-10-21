import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/app_config.dart';

class OneSignalService {
  static String get _appId => AppConfig.oneSignalAppId;
  
  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);
    _setupHandlers();
    print('OneSignal initialized with App ID: $_appId');
  }
  
  static void _setupHandlers() {
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICKED: ${event.notification.notificationId}');
      _handleNotificationOpened(event);
    });
    
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('NOTIFICATION RECEIVED: ${event.notification.notificationId}');
      event.notification.display();
    });
  }
  
  static void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;
    
    print('Notification opened with data: $additionalData');
    
    if (additionalData != null) {
      if (additionalData.containsKey('booking_id')) {
        print('Navigate to booking: ${additionalData['booking_id']}');
      } else if (additionalData.containsKey('type')) {
        print('Notification type: ${additionalData['type']}');
      }
    }
  }
  
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
    print('OneSignal external user ID set: $userId');
  }
  
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
    print('OneSignal external user ID removed');
  }
  
  static String? getSubscriptionId() {
    return OneSignal.User.pushSubscription.id;
  }
  
  static String? getSubscriptionToken() {
    return OneSignal.User.pushSubscription.token;
  }
  
  static bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }
}


