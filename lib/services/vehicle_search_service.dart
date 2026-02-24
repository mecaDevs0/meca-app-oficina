import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class VehicleSearchService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  final Dio _dio = Dio();
  String? _token;

  VehicleSearchService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(seconds: AppConfig.connectionTimeout);
    _dio.options.receiveTimeout = Duration(seconds: AppConfig.receiveTimeout);

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token == null) {
          await loadToken();
        }
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        return handler.next(error);
      },
    ));
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  // Buscar veículo por placa
  Future<Map<String, dynamic>> searchVehicleByPlate(String plate) async {
    try {
      await loadToken();
      if (_token == null) {
        return {'success': false, 'error': 'Usuário não autenticado'};
      }

      // Limpar a placa (remover espaços e converter para maiúscula)
      final cleanPlate = plate.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
      if (cleanPlate.length < 7 || cleanPlate.length > 8) {
        return {'success': false, 'error': 'Placa inválida. Use formato ABC1234 ou ABC1D23'};
      }

      final response = await _dio.get(
        '/vehicles/plate/$cleanPlate',
        options: Options(
          validateStatus: (status) => status != null && status < 600,
          receiveTimeout: const Duration(seconds: 90),
        ),
      );

      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      } else {
        final err = response.data is Map
            ? (response.data?['error'] ?? response.data?['message'] ?? 'Veículo não encontrado')
            : 'Veículo não encontrado';
        return {'success': false, 'error': err.toString()};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Timeout de conexão. Verifique sua internet.';
        case DioExceptionType.badResponse:
          final data = error.response?.data;
          if (data is Map && (data['error'] ?? data['message']) != null) {
            return (data['error'] ?? data['message']).toString();
          }
          if (error.response?.statusCode == 401) {
            return 'Sessão expirada. Faça login novamente.';
          } else if (error.response?.statusCode == 404) {
            return 'Veículo não encontrado.';
          } else if (error.response?.statusCode == 500) {
            return 'Erro ao consultar placa. Tente novamente.';
          }
          return 'Erro na requisição: ${error.response?.statusCode}';
        case DioExceptionType.cancel:
          return 'Requisição cancelada.';
        case DioExceptionType.connectionError:
          return 'Erro de conexão. Verifique sua internet.';
        default:
          return 'Erro desconhecido: ${error.message}';
      }
    }
    return 'Erro: ${error.toString()}';
  }
}
