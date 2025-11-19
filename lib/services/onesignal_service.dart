import 'package:onesignal_flutter/onesignal_flutter.dart';

import '../config/app_config.dart';

class OneSignalService {
  static String get _appId => AppConfig.oneSignalAppId;
  
  static Future<void> initialize() async {
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    OneSignal.initialize(_appId);
    await OneSignal.Notifications.requestPermission(true);
    _setupHandlers();
  }
  
  static void _setupHandlers() {
    OneSignal.Notifications.addClickListener((event) {
      _handleNotificationOpened(event);
    });
    
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      event.notification.display();
    });
  }
  
  static void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;
    
    
    if (additionalData != null) {
      if (additionalData.containsKey('booking_id')) {
      } else if (additionalData.containsKey('type')) {
      }
    }
  }
  
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }
  
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
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












