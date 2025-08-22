import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/service_provider.dart';
import '../controllers/service_controller.dart';

class ServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceProvider>(
      () => ServiceProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<ServiceController>(
      () => ServiceController(
        serviceProvider: Get.find(),
      ),
    );
  }
}
