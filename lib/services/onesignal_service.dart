import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../config/app_config.dart';

class OneSignalService {
  static String get _appId => AppConfig.oneSignalAppId;
  
  static Future<void> initialize() async {
    // Remove this method to prompt for notification permission
    OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
    
    // Initialize OneSignal
    OneSignal.initialize(_appId);
    
    // Request notification permission
    await OneSignal.Notifications.requestPermission(true);
    
    // Setup notification handlers
    _setupHandlers();
  }
  
  static void _setupHandlers() {
    // Handle notification opened
    OneSignal.Notifications.addClickListener((event) {
      print('NOTIFICATION CLICK LISTENER CALLED WITH EVENT: $event');
      // Handle notification click
      _handleNotificationOpened(event);
    });
    
    // Handle notification received in foreground
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('NOTIFICATION WILL DISPLAY LISTENER CALLED WITH: ${event.notification.jsonRepresentation()}');
      // Prevent notification from showing
      // event.preventDefault();
      // or show the notification
      event.notification.display();
    });
  }
  
  static void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;
    
    print('Notification opened with data: $additionalData');
    
    // Handle different types of notifications based on additionalData
    if (additionalData != null) {
      if (additionalData.containsKey('booking_id')) {
        // Navigate to booking detail
        print('Navigate to booking: ${additionalData['booking_id']}');
      } else if (additionalData.containsKey('type')) {
        // Handle other notification types
        print('Notification type: ${additionalData['type']}');
      }
    }
  }
  
  /// Set external user ID (workshop ID)
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
    print('OneSignal external user ID set: $userId');
  }
  
  /// Remove external user ID (logout)
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
    print('OneSignal external user ID removed');
  }
  
  /// Add tag to user
  static Future<void> addTag(String key, String value) async {
    await OneSignal.User.addTag(key, value);
    print('OneSignal tag added: $key = $value');
  }
  
  /// Add multiple tags
  static Future<void> addTags(Map<String, String> tags) async {
    await OneSignal.User.addTags(tags);
    print('OneSignal tags added: $tags');
  }
  
  /// Remove tag
  static Future<void> removeTag(String key) async {
    await OneSignal.User.removeTag(key);
    print('OneSignal tag removed: $key');
  }
  
  /// Get subscription ID
  static String? getSubscriptionId() {
    return OneSignal.User.pushSubscription.id;
  }
  
  /// Get subscription token
  static String? getSubscriptionToken() {
    return OneSignal.User.pushSubscription.token;
  }
  
  /// Check if user is subscribed
  static bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn;
  }
  
  /// Opt in to push notifications
  static Future<void> optIn() async {
    await OneSignal.User.pushSubscription.optIn();
    print('OneSignal: User opted in');
  }
  
  /// Opt out of push notifications
  static Future<void> optOut() async {
    await OneSignal.User.pushSubscription.optOut();
    print('OneSignal: User opted out');
  }
  
  /// Send a test notification (for development)
  static Future<void> sendTestNotification(String message) async {
    print('Test notification: $message');
    // This would typically be done from your backend
  }
  
  /// Set workshop tags for targeting
  static Future<void> setWorkshopTags(String workshopId, String workshopName) async {
    await addTags({
      'workshop_id': workshopId,
      'workshop_name': workshopName,
      'user_type': 'workshop',
      'platform': 'oficina_app',
    });
  }
  
  /// Clear all tags
  static Future<void> clearAllTags() async {
    final tags = OneSignal.User.getTags();
    for (var key in tags.keys) {
      await removeTag(key);
    }
    print('OneSignal: All tags cleared');
  }
}

