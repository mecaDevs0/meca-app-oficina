import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../data/providers/send_quote_provider.dart';
import '../controllers/send_quote_controller.dart';

class SendQuoteBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SendQuoteProvider>(
      () => SendQuoteProvider(
        restClientDio: Get.find(),
      ),
    );
    Get.lazyPut<SendQuoteController>(
      () => SendQuoteController(
        sendQuoteProvider: Get.find(),
        serviceDetailsController: Get.find(),
      ),
    );
  }
}
