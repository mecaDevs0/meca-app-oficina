import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/home_provider.dart';
import '../controllers/home_controller.dart';

class HomeBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<HomeProvider>(
      () => HomeProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<HomeController>(
      () => HomeController(
        homeProvider: Get.find(),
        coreController: Get.find(),
      ),
    );
  }
}
