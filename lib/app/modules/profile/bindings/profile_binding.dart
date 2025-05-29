import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/profile_provider.dart';
import '../controllers/profile_controller.dart';

class ProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProfileProvider>(
      () => ProfileProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<ProfileController>(
      () => ProfileController(
        coreController: Get.find(),
      ),
    );
  }
}
