import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../data/data.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final workshop = WorkshopModel.fromCache();
    if (options.method == 'GET' && workshop.id != null) {
      options.queryParameters['workshopId'] = workshop.id;
    }
    options.queryParameters['dataBlocked'] = 0;
    handler.next(options);
  }
}
