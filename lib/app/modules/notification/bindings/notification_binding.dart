import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/notification_provider.dart';
import '../controllers/notification_controller.dart';

class AppNotificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<NotificationProvider>(
      () => NotificationProvider(
        restClientDio: Get.find(),
      ),
    );

    Get.lazyPut<AppNotificationController>(
      () => AppNotificationController(
        notificationProvider: Get.find(),
      ),
    );
  }
}
