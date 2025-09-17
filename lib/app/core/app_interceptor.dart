import 'dart:developer' as console;

import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../data/data.dart';

class AppInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Verificar se é uma requisição de autenticação antes de tentar acessar o cache
    final isAuthRequest = options.path.contains('/Token') || 
                         options.path.contains('/Register') ||
                         options.path.contains('/ForgotPassword');
    
    WorkshopModel? workshop;
    try {
      workshop = WorkshopModel.fromCache();
    } catch (e) {
      console.log('⚠️ AppInterceptor - Erro ao acessar cache do workshop: $e', name: 'AppInterceptor');
      workshop = null;
    }
    
    console.log('🏭 AppInterceptor - Workshop ID: ${workshop?.id ?? "null"}', name: 'AppInterceptor');
    console.log('🏭 AppInterceptor - Path: ${options.path}', name: 'AppInterceptor');
    console.log('🏭 AppInterceptor - Method: ${options.method}', name: 'AppInterceptor');
    
    // Adicionar workshopId apenas se a oficina estiver logada e não for uma requisição de autenticação
    // E não for um endpoint que já tem ID na URL (como WorkshopAgenda/{id})
    // E não for um endpoint de serviços padrão (ServicesDefault)
    if (!isAuthRequest &&
        options.method == 'GET' && 
        workshop?.id != null && 
        workshop!.id!.isNotEmpty && 
        !options.path.contains('/WorkshopAgenda/') &&
        !options.path.contains('/ServicesDefault')) {
      options.queryParameters['workshopId'] = workshop.id;
      console.log('✅ AppInterceptor - Adicionando workshopId: ${workshop.id}', name: 'AppInterceptor');
    } else {
      console.log('❌ AppInterceptor - NÃO adicionando workshopId', name: 'AppInterceptor');
      console.log('❌ Motivo: isAuthRequest=$isAuthRequest, method=${options.method}, workshop.id=${workshop?.id ?? "null"}, path=${options.path}', name: 'AppInterceptor');
    }
    
    // Adicionar dataBlocked apenas em requisições GET que não são de autenticação
    // E não para endpoints de serviços padrão (ServicesDefault)
    if (!isAuthRequest && 
        options.method == 'GET' && 
        !options.path.contains('/ServicesDefault')) {
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
    console.log('❌ Erro Oficina: ${err.response?.statusCode} ${err.requestOptions.method} ${err.requestOptions.path}', 
        name: 'AppInterceptor');
    console.log('❌ Mensagem: ${err.message}', name: 'AppInterceptor');
    handler.next(err);
  }
}
