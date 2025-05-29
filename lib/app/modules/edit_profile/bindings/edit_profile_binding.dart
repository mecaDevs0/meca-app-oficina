import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/edit_profile_provider.dart';
import '../controllers/edit_profile_controller.dart';

class EditProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<EditProfileProvider>(
      () => EditProfileProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<EditProfileController>(
      () => EditProfileController(
        editProfileProvider: Get.find(),
        formAddressController: Get.find(),
      ),
    );
  }
}
