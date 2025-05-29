import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/create_service_provider.dart';
import '../controllers/create_service_controller.dart';

class CreateServiceBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<CreateServiceProvider>(
      () => CreateServiceProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<CreateServiceController>(
      () => CreateServiceController(
        createServiceProvider: Get.find(),
      ),
    );
  }
}
