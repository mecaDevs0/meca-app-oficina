import 'dart:io';

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

class EvidenceService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  final Dio _dio = Dio();
  String? _token;

  EvidenceService() {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = Duration(seconds: AppConfig.connectionTimeout);
    _dio.options.receiveTimeout = Duration(seconds: AppConfig.receiveTimeout);
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
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
    
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    } else {
      _dio.options.headers.remove('Authorization');
    }
  }

  // Upload de evidências para agendamento
  Future<Map<String, dynamic>> uploadBookingEvidence(
    String bookingId,
    File file,
  ) async {
    try {
      await loadToken();
      
      final formData = FormData.fromMap({
        'evidence': await MultipartFile.fromFile(
          file.path,
          filename: file.path.split('/').last,
        ),
      });

      final response = await _dio.post(
        '/bookings/$bookingId/images',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'] ?? responseData,
            'message': responseData['message'] ?? 'Evidência enviada com sucesso'
          };
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': 'Erro no upload da evidência'};
      }
    } catch (e) {
      String errorMessage = 'Erro de conexão';
      if (e is DioException) {
        if (e.response != null) {
          final errorData = e.response?.data;
          if (errorData is Map && errorData['error']) {
            errorMessage = errorData['error'].toString();
          } else {
            errorMessage = 'Erro ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Erro desconhecido'}';
          }
        } else {
          errorMessage = 'Erro de conexão: ${e.message ?? e.toString()}';
        }
      } else {
        errorMessage = 'Erro: ${e.toString()}';
      }
      return {'success': false, 'error': errorMessage};
    }
  }

  // Obter evidências de um agendamento
  Future<Map<String, dynamic>> getBookingEvidence(String bookingId) async {
    try {
      await loadToken();
      
      final response = await _dio.get('/bookings/$bookingId/images');
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        if (responseData is Map && responseData['success'] == true) {
          return {
            'success': true,
            'data': responseData['data'] ?? []
          };
        }
        // Se não tem estrutura {success, data}, assumir que responseData é a lista
        if (responseData is List) {
          return {'success': true, 'data': responseData};
        }
        return {'success': true, 'data': responseData};
      } else {
        return {'success': false, 'error': 'Erro ao buscar evidências'};
      }
    } catch (e) {
      String errorMessage = 'Erro de conexão';
      if (e is DioException) {
        if (e.response != null) {
          if (e.response?.statusCode == 404) {
            // Se 404, retornar lista vazia ao invés de erro
            return {'success': true, 'data': []};
          }
          final errorData = e.response?.data;
          if (errorData is Map && errorData['error']) {
            errorMessage = errorData['error'].toString();
          } else {
            errorMessage = 'Erro ${e.response?.statusCode}: ${e.response?.statusMessage ?? 'Erro desconhecido'}';
          }
        } else {
          errorMessage = 'Erro de conexão: ${e.message ?? e.toString()}';
        }
      } else {
        errorMessage = 'Erro: ${e.toString()}';
      }
      return {'success': false, 'error': errorMessage};
    }
  }
}
