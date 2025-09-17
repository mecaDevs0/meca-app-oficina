import 'package:get/get.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

class BankAccountBinding extends Bindings {
  BankAccountBinding();

  @override
  void dependencies() {
    // Usar o mesmo RestClientDio que já está configurado com AppInterceptor
    final restClientDio = Get.find<RestClientDio>();
    
    // Criar o BankAccountProvider do mega_features
    Get.put<BankAccountProvider>(
      BankAccountProvider(
        megaApi: restClientDio,
        restClientDio: restClientDio,
      ),
    );

    // Usar o BankAccountController do mega_features
    Get.put<BankAccountController>(
      BankAccountController(
        bankProvider: Get.find(),
      ),
    );
  }
}
