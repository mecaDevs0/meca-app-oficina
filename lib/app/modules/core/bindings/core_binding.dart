import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/profile_provider.dart';
import '../controllers/core_controller.dart';

class CoreBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileProvider>(
      () => ProfileProvider(restClientDio: Get.find()),
    );

    Get.lazyPut<CoreController>(
      () => CoreController(profileProvider: Get.find()),
    );
  }
}
