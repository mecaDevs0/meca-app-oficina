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
        print('Evidence Service Error: ${error.message}');
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
        '/store/booking/$bookingId/evidence',
        data: formData,
        options: Options(
          headers: {
            'Content-Type': 'multipart/form-data',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro no upload da evidência'};
      }
    } catch (e) {
      print('Erro no upload de evidência: $e');
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  // Obter evidências de um agendamento
  Future<Map<String, dynamic>> getBookingEvidence(String bookingId) async {
    try {
      await loadToken();
      
      final response = await _dio.get('/store/booking/$bookingId/evidence');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro ao buscar evidências'};
      }
    } catch (e) {
      print('Erro ao buscar evidências: $e');
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }
}
