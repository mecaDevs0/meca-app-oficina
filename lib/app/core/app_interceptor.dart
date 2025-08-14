import 'dart:developer' as console;
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../data/data.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final workshop = WorkshopModel.fromCache();
    
    // Adicionar workshopId apenas se a oficina estiver logada e não for uma requisição de autenticação
    if (options.method == 'GET' && 
        workshop.id != null && 
        !options.path.contains('/Token') && 
        !options.path.contains('/Register') &&
        !options.path.contains('/ForgotPassword')) {
      options.queryParameters['workshopId'] = workshop.id;
    }
    
    // Adicionar dataBlocked apenas em requisições que não são de autenticação
    if (!options.path.contains('/Token') && 
        !options.path.contains('/Register') &&
        !options.path.contains('/ForgotPassword')) {
      options.queryParameters['dataBlocked'] = 0;
    }
    
    // Log detalhado da requisição para debug
    console.log('🏭 Requisição Oficina: ${options.method} ${options.baseUrl}${options.path}', 
        name: 'AppInterceptor');
    console.log('📡 Headers: ${options.headers}', name: 'AppInterceptor');
    console.log('🔍 Query Params: ${options.queryParameters}', name: 'AppInterceptor');
    
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    console.log('✅ Resposta Oficina: ${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.path}', 
        name: 'AppInterceptor');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    console.log('❌ Erro de rede Oficina: ${err.type}', name: 'AppInterceptor');
    console.log('📊 Status: ${err.response?.statusCode}', name: 'AppInterceptor');
    console.log('🔗 URL: ${err.requestOptions.uri}', name: 'AppInterceptor');
    console.log('💬 Mensagem: ${err.message}', name: 'AppInterceptor');
    
    handler.next(err);
  }
}
