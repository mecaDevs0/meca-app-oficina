import 'package:get/get.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/mega_features.dart';

import '../data/providers/bank_account_provider.dart';

class BankAccountBinding extends Bindings {
  BankAccountBinding();

  @override
  void dependencies() {
    // Usar o mesmo RestClientDio que já está configurado com AppInterceptor
    final restClientDio = Get.find<RestClientDio>();
    
    Get.put<BankAccountProvider>(
      BankAccountProvider(
        megaApi: restClientDio, // Usar o mesmo cliente
        restClientDio: restClientDio, // Usar o mesmo cliente
      ),
    );

    Get.put<BankAccountController>(
      BankAccountController(
        bankProvider: Get.find(),
      ),
    );
  }
}
