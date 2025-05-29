import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/schedule_provider.dart';
import '../controllers/schedule_controller.dart';

class ScheduleBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ScheduleProvider>(
      () => ScheduleProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<ScheduleController>(
      () => ScheduleController(
        scheduleProvider: Get.find(),
      ),
    );
  }
}
