import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

void configureDioForProduction(Dio dio) {
  if (dio.httpClientAdapter is IOHttpClientAdapter) {
    (dio.httpClientAdapter as IOHttpClientAdapter).createHttpClient = () {
      return HttpClient(context: SecurityContext(withTrustedRoots: true));
    };
  }
}
