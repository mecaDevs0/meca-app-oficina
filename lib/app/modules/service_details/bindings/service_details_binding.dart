import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/service_details_provider.dart';
import '../controllers/service_details_controller.dart';

class ServiceDetailsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ServiceDetailsProvider>(
      () => ServiceDetailsProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<ServiceDetailsController>(
      () => ServiceDetailsController(
        serviceDetailsProvider: Get.find(),
      ),
    );
  }
}
