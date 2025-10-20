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
      onRequest: (options, handler) {
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
      // Atualizar headers com o token
      _dio.options.headers['Authorization'] = 'Bearer $_token';
      print('Token carregado: ${_token!.substring(0, 20)}...');
    } else {
      print('Token não encontrado');
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

  // Helper para escolher entre endpoints admin e store
  String _getEndpoint(String storePath, String adminPath) {
    return useAdminEndpoints ? adminPath : storePath;
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
      final response = await _dio.post('/public/workshops/login', data: {
        'email': email,
        'password': password,
      });
      
      if (response.data['token'] != null) {
        await saveToken(response.data['token']);
      }
      
      return {'success': true, 'data': response.data};
    } catch (e) {
      print('Login error: $e');
      return {'success': false, 'error': 'Erro ao fazer login. Verifique suas credenciais.'};
    }
  }

  Future<Map<String, dynamic>> getWorkshopDashboard() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Buscar dados completos da oficina incluindo configurações
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        
        final workshop = Map<String, dynamic>.from(workshops[0]);
        
        // Buscar serviços da oficina
        try {
          final productsResponse = await _dio.get('/admin/products', queryParameters: {'limit': 100});
          final products = productsResponse.data['products'] as List? ?? [];
          final workshopServices = products.where((p) => 
            p['metadata']?['oficina_id'] == workshop['id']
          ).toList();
          workshop['services'] = workshopServices;
        } catch (e) {
          print('Erro ao buscar serviços: $e');
          workshop['services'] = [];
        }
        
        // Retornar dados completos da oficina (inclui dados_bancarios, horario_funcionamento, etc)
        return {'success': true, 'data': workshop};
      } else {
        final response = await _dio.get('/store/workshops/me/dashboard');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error getWorkshopDashboard: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getProfile() async {
    try {
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
      print('API Error getMyBookings: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      final response = await _dio.get('/workshop/bookings/$id');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    try {
      final response = await _dio.post('/store/workshops/me/bookings/$bookingId/confirm');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
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
      final response = await _dio.post('/workshop/bookings/$bookingId/start');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeService(String bookingId) async {
    try {
      final response = await _dio.post('/workshop/bookings/$bookingId/complete');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Services
  Future<Map<String, dynamic>> getMasterServices() async {
    try {
      // Endpoint público - não precisa de token
      final response = await _dio.get('/public/master-services');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMyServices() async {
    try {
      await loadToken(); // Carregar token antes da requisição
      
      if (useAdminEndpoints) {
        // Para admin, buscar produtos da oficina logada
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': true, 'data': {'services': []}};
        }
        final workshopId = workshops[0]['id'];
        
        // Buscar todos os produtos e filtrar pelos da oficina
        final productsResponse = await _dio.get('/admin/products', queryParameters: {'limit': 100});
        final products = productsResponse.data['products'] as List? ?? [];
        
        final workshopServices = products.where((p) => 
          p['metadata']?['oficina_id'] == workshopId
        ).toList();
        
        return {'success': true, 'data': {'services': workshopServices}};
      } else {
        final response = await _dio.get('/store/workshops/me/services');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('Erro ao buscar serviços: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addService({
    required String title,
    required double price,
    required int durationMinutes,
    String? description,
    String? thumbnail,
    List<String>? images,
  }) async {
    try {
      await loadToken(); // Carregar token antes da requisição
      
      if (useAdminEndpoints) {
        // Para admin, criar produto via endpoint admin
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        final workshopId = workshops[0]['id'];
        
        // Criar produto com metadata da oficina
        final productData = {
          'title': title,
          'description': description ?? '',
          'is_giftcard': false,
          'discountable': true,
          'options': [],
          'variants': [
            {
              'title': 'Default',
              'prices': [
                {
                  'amount': (price * 100).round(),
                  'currency_code': 'brl',
                }
              ],
              'options': [],
            }
          ],
          'metadata': {
            'oficina_id': workshopId.toString(),
            'duration_minutes': durationMinutes.toString(),
            'service_type': 'workshop_service',
          },
        };
        
        print('Creating product with data: $productData');
        final response = await _dio.post('/admin/products', data: productData);
        print('Product created successfully: ${response.data}');
        return {'success': true, 'data': response.data};
      } else {
        final response = await _dio.post('/store/workshops/me/services', data: {
          'title': title,
          'description': description ?? '',
          'price': (price * 100).round(), // Converter para centavos
          'duration_minutes': durationMinutes,
          'thumbnail': thumbnail,
          'images': images ?? [],
        });
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error addService: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    int? price,
    int? durationMinutes,
    String? description,
    bool? isActive,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (price != null) data['price'] = price;
      if (durationMinutes != null) data['duration_minutes'] = durationMinutes;
      if (description != null) data['description'] = description;
      if (isActive != null) data['is_active'] = isActive;

      final response = await _dio.put('/workshop/services/$serviceId', data: data);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Schedule
  Future<Map<String, dynamic>> getSchedule() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Para admin, usar o primeiro ID de oficina disponível
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        
        final schedule = workshops[0]['horario_funcionamento'];
        return {'success': true, 'data': {'schedule': schedule ?? {}}};
      } else {
        final response = await _dio.get('/store/workshops/me/schedule');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error getSchedule: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSchedule(Map<String, dynamic> schedule) async {
    try {
      await loadToken(); // Carregar token antes da requisição
      
      if (useAdminEndpoints) {
        // Para admin, usar o primeiro ID de oficina disponível
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        final workshopId = workshops[0]['id'];
        
        final response = await _dio.put('/admin/workshops/$workshopId', data: {
          'horario_funcionamento': schedule,
        });
        return {'success': true, 'data': response.data};
      } else {
        final response = await _dio.put('/store/workshops/me/schedule', data: {'schedule': schedule});
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Financial
  Future<Map<String, dynamic>> getFinancialSummary({
    String? startDate,
    String? endDate,
  }) async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Retornar resumo financeiro vazio para modo admin
        return {'success': true, 'data': {
          'total_revenue': 0,
          'pending_payments': 0,
          'completed_services': 0,
          'transactions': []
        }};
      } else {
        final queryParams = <String, dynamic>{};
        if (startDate != null) queryParams['start_date'] = startDate;
        if (endDate != null) queryParams['end_date'] = endDate;
        
        final response = await _dio.get('/store/workshops/me/financial', queryParameters: queryParams);
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error getFinancialSummary: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Bank Details
  Future<Map<String, dynamic>> getBankAccount() async {
    try {
      await loadToken();
      
      if (useAdminEndpoints) {
        // Para admin, usar o primeiro ID de oficina disponível
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        
        final bankAccount = workshops[0]['dados_bancarios'];
        return {'success': true, 'data': bankAccount ?? {}};
      } else {
        final response = await _dio.get('/store/workshops/me/bank-account');
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error getBankAccount: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBankAccount({
    required String bankName,
    required String accountType,
    required String accountNumber,
    required String agencyNumber,
    required String accountHolderName,
    required String accountHolderDocument,
    required String pixKey,
    required String pixKeyType,
  }) async {
    try {
      await loadToken(); // Carregar token antes da requisição
      
      if (useAdminEndpoints) {
        // Para admin, usar o primeiro ID de oficina disponível
        final workshopsResponse = await _dio.get('/admin/workshops');
        final workshops = workshopsResponse.data['oficinas'] as List;
        if (workshops.isEmpty) {
          return {'success': false, 'error': 'Nenhuma oficina encontrada'};
        }
        final workshopId = workshops[0]['id'];
        
        final bankData = {
          'bank_name': bankName,
          'account_type': accountType,
          'account_number': accountNumber,
          'agency_number': agencyNumber,
          'account_holder_name': accountHolderName,
          'account_holder_document': accountHolderDocument,
          'pix_key': pixKey,
          'pix_key_type': pixKeyType,
        };
        
        final response = await _dio.put('/admin/workshops/$workshopId', data: {
          'dados_bancarios': bankData,
        });
        return {'success': true, 'data': response.data};
      } else {
        final response = await _dio.put('/store/workshops/me/bank-account', data: {
          'bank_name': bankName,
          'account_type': accountType,
          'account_number': accountNumber,
          'agency_number': agencyNumber,
          'account_holder_name': accountHolderName,
          'account_holder_document': accountHolderDocument,
          'pix_key': pixKey,
          'pix_key_type': pixKeyType,
        });
        return {'success': true, 'data': response.data};
      }
    } catch (e) {
      print('API Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // Images
  Future<Map<String, dynamic>> uploadImage({
    required String imageType,
    required String imageData,
    String? serviceId,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/images', data: {
        'image_type': imageType,
        'image_data': imageData,
        if (serviceId != null) 'service_id': serviceId,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getImages({String? imageType, String? serviceId}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (imageType != null) queryParams['image_type'] = imageType;
      if (serviceId != null) queryParams['service_id'] = serviceId;

      final response = await _dio.get('/store/workshops/me/images', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteImage({
    required String imageType,
    int? imageIndex,
    String? serviceId,
  }) async {
    try {
      final response = await _dio.delete('/store/workshops/me/images', data: {
        'image_type': imageType,
        if (imageIndex != null) 'image_index': imageIndex,
        if (serviceId != null) 'service_id': serviceId,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Notifications
  Future<Map<String, dynamic>> getNotifications({bool unreadOnly = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (unreadOnly) queryParams['unread_only'] = 'true';

      final response = await _dio.get('/store/workshops/me/notifications', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _dio.put('/store/workshops/me/notifications/$notificationId/read');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // WhatsApp Notifications
  Future<Map<String, dynamic>> getPendingNotifications() async {
    try {
      final response = await _dio.get('/store/workshops/me/notifications/pending');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> scheduleNotification({
    required String bookingId,
    required String type,
    required DateTime scheduledFor,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/notifications/schedule', data: {
        'booking_id': bookingId,
        'type': type,
        'scheduled_for': scheduledFor.toIso8601String(),
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsSent(String notificationId) async {
    try {
      final response = await _dio.put('/store/workshops/me/notifications/$notificationId/sent');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendWhatsAppMessage({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/whatsapp/send', data: {
        'phone_number': phoneNumber,
        'message': message,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // PagBank
  Future<Map<String, dynamic>> getPagBankAccount() async {
    try {
      final response = await _dio.get('/store/workshops/me/pagbank');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPagBankAccount({
    required String name,
    required String email,
    required String document,
    required String type,
    required Map<String, dynamic> address,
    required Map<String, dynamic> phone,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/pagbank', data: {
        'name': name,
        'email': email,
        'document': document,
        'type': type,
        'address': address,
        'phone': phone,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPagBankBankAccounts() async {
    try {
      final response = await _dio.get('/store/workshops/me/pagbank/bank-accounts');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPagBankBankAccount({
    required String accountNumber,
    required String bankCode,
    required String agencyNumber,
    required String holderName,
    required String holderType,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/pagbank/bank-accounts', data: {
        'account_number': accountNumber,
        'bank_code': bankCode,
        'agency_number': agencyNumber,
        'holder_name': holderName,
        'holder_type': holderType,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> testPagBankConnection() async {
    try {
      final response = await _dio.get('/store/workshops/me/pagbank/test');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPagBankPayments({
    int limit = 50,
    int offset = 0,
    String? startDate,
    String? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'limit': limit,
        'offset': offset,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;

      final response = await _dio.get('/store/workshops/me/pagbank/payments', queryParameters: queryParams);
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> createPagBankPayment({
    required int amount,
    required String customerId,
    String? description,
  }) async {
    try {
      final response = await _dio.post('/store/workshops/me/pagbank/payments', data: {
        'amount': amount,
        'customer_id': customerId,
        'description': description,
      });
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Reviews
  Future<Map<String, dynamic>> getMyReviews() async {
    try {
      final response = await _dio.get('/workshop/reviews');
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}

