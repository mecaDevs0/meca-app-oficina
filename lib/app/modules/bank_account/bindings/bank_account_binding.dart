import 'package:get/get.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

class BankAccountBinding extends Bindings {
  BankAccountBinding();

  @override
  void dependencies() {
    // Usar o BankAccountProvider do mega_features com URL base correta
    Get.put<BankAccountProvider>(
      BankAccountProvider(
        megaApi: RestClientDio('https://api.mecabr.com/api/v1/'),
        restClientDio: Get.find(),
      ),
    );

    Get.put<BankAccountController>(
      BankAccountController(
        bankProvider: Get.find(),
      ),
    );
  }
}
