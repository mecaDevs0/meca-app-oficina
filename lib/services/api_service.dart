import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  // API configurada no AppConfig (EC2 AWS)
  static String get baseUrl => AppConfig.apiBaseUrl;
  static bool get useAdminEndpoints => AppConfig.useAdminEndpoints;
  final Dio _dio = Dio();
  String? _token;

  ApiService() {
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
        print('API Error: ${error.message}');
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

  Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // Auth
  Future<Map<String, dynamic>> registerWorkshop(Map<String, dynamic> data) async {
    try {
      final response = await _dio.post('/public/workshops', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String cnpj,
    required String phone,
    required Map<String, dynamic> address,
  }) async {
    try {
      final response = await _dio.post('/auth/workshop/register', data: {
        'name': name,
        'email': email,
        'password': password,
        'cnpj': cnpj,
        'phone': phone,
        'address': address,
      });
      
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post('/auth/workshop/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> logout() async {
    try {
      await clearToken();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Profile
  Future<Map<String, dynamic>> getProfile() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Para admin, buscar todas as oficinas e retornar a primeira (simulação de "me")
        final response = await _dio.get('/admin/workshops');
        final oficinas = response.data['oficinas'] as List;
        if (oficinas.isNotEmpty) {
          final oficina = Map<String, dynamic>.from(oficinas[0]);
          
          // Buscar serviços da oficina (products com metadata.oficina_id)
          try {
            final servicesResponse = await _dio.get('/admin/products', queryParameters: {'limit': 100});
            final products = servicesResponse.data['products'] as List?;
            if (products != null) {
              final oficinaServices = products.where((p) => 
                p['metadata']?['oficina_id'] == oficina['id']
              ).toList();
              oficina['services'] = oficinaServices;
            } else {
              oficina['services'] = [];
            }
          } catch (e) {
            print('Erro ao buscar serviços: $e');
            oficina['services'] = [];
          }
          
          return {'success': true, 'data': oficina};
        } else {
          return {'success': false, 'error': 'Oficina não encontrada'};
        }
      } else {
        final response = await _dio.get('/store/workshops/me');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Para admin, atualizar a primeira oficina encontrada
        final response = await _dio.put('/admin/workshops/me', data: data);
        return {'success': true, 'data': response.data};
      } else {
        final response = await _dio.put('/store/workshops/me', data: data);
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Bookings
  Future<Map<String, dynamic>> getMyBookings({String? status}) async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Retornar lista vazia de bookings para modo admin
        return {'success': true, 'data': {'bookings': []}};
      } else {
        final queryParams = <String, dynamic>{};
        if (status != null) queryParams['status'] = status;
        
        final response = await _dio.get('/store/workshops/me/bookings', queryParameters: queryParams);
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      await loadToken();
      final response = await _dio.get('/store/workshops/me/bookings/$id');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/confirm');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
      await loadToken();
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/reject', data: {
        'reason': reason,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> suggestNewTime(String bookingId, String suggestedDate, String reason) async {
    try {
      await loadToken();
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/suggest-time', data: {
        'suggested_date': suggestedDate,
        'reason': reason,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startService(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/start');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> finishService(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/finish');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Services
  Future<Map<String, dynamic>> getServices() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        final response = await _dio.get('/admin/products', queryParameters: {'limit': 100});
        return {'success': true, 'data': response.data['products'] ?? []};
      } else {
        final response = await _dio.get('/store/products', queryParameters: {'limit': 100});
        return {'success': true, 'data': response.data['products'] ?? []};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWorkshopServices(String workshopId) async {
    try {
      await loadToken();
      final response = await _dio.get('/store/workshops/$workshopId/services');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Workshops
  Future<Map<String, dynamic>> getWorkshops() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        final response = await _dio.get('/admin/workshops');
        return {'success': true, 'data': response.data['oficinas'] ?? []};
      } else {
        final response = await _dio.get('/store/workshops');
        return {'success': true, 'data': response.data['workshops'] ?? []};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Dashboard
  Future<Map<String, dynamic>> getWorkshopDashboard() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Para admin, retornar dados simulados
        return {
          'success': true,
          'data': {
            'total_bookings': 0,
            'pending_bookings': 0,
            'confirmed_bookings': 0,
            'completed_bookings': 0,
            'monthly_revenue': 0.0,
          }
        };
      } else {
        final response = await _dio.get('/store/workshops/me/dashboard');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Financial
  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        return {
          'success': true,
          'data': {
            'total_revenue': 0.0,
            'monthly_revenue': 0.0,
            'pending_payments': 0.0,
            'completed_payments': 0.0,
          }
        };
      } else {
        final response = await _dio.get('/store/workshops/me/financial');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        return {'success': true, 'data': []};
      } else {
        final response = await _dio.get('/store/workshops/me/notifications');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      await loadToken();
      final response = await _dio.put('/store/workshops/me/notifications/$notificationId/read');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Métodos adicionais para funcionalidades específicas
  Future<Map<String, dynamic>> completeService(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.put('/api/bookings/$bookingId/complete');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getSchedule() async {
    try {
      await loadToken();
      final response = await _dio.get('/api/workshops/me/schedule');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSchedule(Map<String, dynamic> scheduleData) async {
    try {
      await loadToken();
      final response = await _dio.put('/api/workshops/me/schedule', data: scheduleData);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}