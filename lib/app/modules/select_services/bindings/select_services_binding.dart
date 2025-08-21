import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/create_service_provider.dart';
import '../controllers/select_services_controller.dart';

class SelectServicesBinding extends Bindings {
  SelectServicesBinding();

  @override
  void dependencies() {
    Get.put<CreateServiceProvider>(
      CreateServiceProvider(
        restClientDio: Get.find(),
      ),
    );

    Get.put<SelectServicesController>(
      SelectServicesController(
        createServiceProvider: Get.find(),
      ),
    );
  }
}
