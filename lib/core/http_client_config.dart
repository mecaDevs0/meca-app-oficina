import 'package:dio/dio.dart';

import 'http_client_config_stub.dart'
    if (dart.library.io) 'http_client_config_io.dart' as impl;

void configureDioForProduction(Dio dio) {
  impl.configureDioForProduction(dio);
}
