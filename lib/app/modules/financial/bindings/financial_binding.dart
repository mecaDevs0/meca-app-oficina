import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/financial_provider.dart';
import '../controllers/financial_controller.dart';

class FinancialBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FinancialProvider>(
      () => FinancialProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<FinancialController>(
      () => FinancialController(
        financialProvider: Get.find(),
      ),
    );
  }
}
