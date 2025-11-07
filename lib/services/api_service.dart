import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class ApiService {
  // API configurada no AppConfig (EC2 AWS) - DADOS REAIS
  static String get baseUrl => AppConfig.apiBaseUrl;
  final Dio _dio = Dio();
  String? _token;
  String? _workshopId; // Cache do workshopId do token

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
      // Decodificar JWT para obter workshopId
      _workshopId = _decodeJWT(_token!);
    } else {
      _dio.options.headers.remove('Authorization');
      _workshopId = null;
    }
  }

  // Decodificar JWT (base64) para obter workshopId
  String? _decodeJWT(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      
      // Decodificar payload (parte 2)
      String payload = parts[1];
      // Adicionar padding se necessário
      switch (payload.length % 4) {
        case 1:
          payload += '===';
          break;
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }
      
      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);
      
      // Retornar workshopId ou userId (a API pode usar qualquer um)
      return payloadMap['workshopId'] ?? payloadMap['userId'] ?? payloadMap['id'];
    } catch (e) {
      print('Erro ao decodificar JWT: $e');
      return null;
    }
  }

  // Obter workshopId atual (do token ou cache)
  Future<String?> getWorkshopId() async {
    if (_workshopId != null) return _workshopId;
    
    await loadToken();
    if (_token == null) return null;
    
    // Se ainda não tem workshopId, tentar buscar do perfil
    try {
      final profile = await getProfile();
      if (profile['success'] && profile['data'] != null) {
        _workshopId = profile['data']['id'] as String?;
        return _workshopId;
      }
    } catch (e) {
      print('Erro ao obter workshopId do perfil: $e');
    }
    
    return null;
  }

  Future<void> saveToken(String token) async {
    _token = token;
    _workshopId = _decodeJWT(token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (_token != null) {
      _dio.options.headers['Authorization'] = 'Bearer $_token';
    }
  }

  Future<void> clearToken() async {
    _token = null;
    _workshopId = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _dio.options.headers.remove('Authorization');
  }

  // ============================================
  // AUTH - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> registerWorkshop(Map<String, dynamic> data) async {
    try {
      // Preparar dados no formato esperado pela API
      final address = data['address'] as Map<String, dynamic>? ?? {};
      
      // Construir endereço completo se houver logradouro e número
      String fullAddress = '';
      if (address['logradouro'] != null && address['logradouro'].toString().isNotEmpty) {
        fullAddress = address['logradouro'].toString();
        if (address['numero'] != null && address['numero'].toString().isNotEmpty) {
          fullAddress += ', ${address['numero']}';
        }
        if (address['bairro'] != null && address['bairro'].toString().isNotEmpty) {
          fullAddress += ' - ${address['bairro']}';
        }
      }
      
      final requestData = {
        'email': data['email']?.toString().trim() ?? '',
        'password': data['password']?.toString() ?? '',
        'name': data['name']?.toString().trim() ?? '',
        'cnpj': data['cnpj']?.toString().replaceAll(RegExp(r'\D'), '') ?? '',
        'phone': data['phone']?.toString().replaceAll(RegExp(r'\D'), '') ?? '',
        'address': fullAddress,
        'city': address['cidade']?.toString().trim() ?? '',
        'state': address['estado']?.toString().trim() ?? '',
        'cep': address['cep']?.toString().replaceAll(RegExp(r'\D'), '') ?? '',
        'latitude': null, // Será calculado via CEP ou geolocalização
        'longitude': null, // Será calculado via CEP ou geolocalização
      };
      
      // Validar campos obrigatórios
      if (requestData['email']!.isEmpty || 
          requestData['password']!.isEmpty || 
          requestData['name']!.isEmpty || 
          requestData['cnpj']!.isEmpty) {
        return {
          'success': false,
          'error': 'Email, senha, nome e CNPJ são obrigatórios'
        };
      }
      
      final response = await _dio.post('/auth/workshop/register', data: requestData);
      
      // Verificar se a resposta é bem-sucedida
      if (response.data['success'] == true) {
        // Se a resposta incluir token, salvar automaticamente
        if (response.data['data']?['token'] != null) {
          await saveToken(response.data['data']['token']);
        } else if (response.data['data']?['workshop']?['token'] != null) {
          await saveToken(response.data['data']['workshop']['token']);
        } else if (response.data['token'] != null) {
          await saveToken(response.data['token']);
        }
        
        return {'success': true, 'data': response.data};
      } else {
        return {
          'success': false,
          'error': response.data['error']?.toString() ?? 'Erro ao registrar oficina'
        };
      }
    } on DioException catch (e) {
      // Tratar erros específicos do Dio
      String errorMessage = 'Erro ao registrar oficina';
      
      if (e.response != null) {
        // Erro com resposta do servidor
        final statusCode = e.response?.statusCode;
        final errorData = e.response?.data;
        
        if (errorData is Map && errorData['error'] != null) {
          errorMessage = errorData['error'].toString();
        } else if (statusCode == 404) {
          errorMessage = 'Endpoint não encontrado. Verifique a URL da API.';
        } else if (statusCode == 400) {
          errorMessage = errorData?['error']?.toString() ?? 'Dados inválidos';
        } else if (statusCode == 500) {
          errorMessage = 'Erro interno do servidor. Tente novamente mais tarde.';
        } else {
          errorMessage = 'Erro ${statusCode}: ${errorData?.toString() ?? e.message}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Tempo de conexão esgotado. Verifique sua conexão com a internet.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Erro de conexão. Verifique se a API está online.';
      } else {
        errorMessage = e.message ?? 'Erro desconhecido ao registrar oficina';
      }
      
      return {'success': false, 'error': errorMessage};
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
      
      if (response.data['data']?['token'] != null) {
        await saveToken(response.data['data']['token']);
      } else if (response.data['token'] != null) {
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
      
      if (response.data['data']?['token'] != null) {
        await saveToken(response.data['data']['token']);
      } else if (response.data['token'] != null) {
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

  // ============================================
  // PROFILE - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getProfile() async {
    try {
      await loadToken();
      
      // Obter workshopId do token
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id
      final response = await _dio.get('/workshop/$workshopId');
      final oficina = Map<String, dynamic>.from(response.data['data'] ?? response.data);

      oficina['address'] = _normalizeAddress(oficina['address']);
      oficina['latitude'] = oficina['latitude']?.toString();
      oficina['longitude'] = oficina['longitude']?.toString();

      try {
        final servicesResponse = await _dio.get('/workshop/$workshopId/services');
        oficina['services'] = _extractServicesList(servicesResponse.data['data'] ?? servicesResponse.data ?? []);
      } catch (e) {
        oficina['services'] = [];
      }

      return {'success': true, 'data': oficina};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    try {
      await loadToken();
      
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: PUT /workshop/:id
      final response = await _dio.put('/workshop/$workshopId', data: data);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateWorkshop(String workshopId, Map<String, dynamic> data) async {
    try {
      await loadToken();
      
      // Usar endpoint real: PUT /workshop/:id
      final response = await _dio.put('/workshop/$workshopId', data: data);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // BOOKINGS - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getMyBookings({String? status}) async {
    try {
      await loadToken();
      
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/bookings
      final response = await _dio.get('/workshop/$workshopId/bookings');
      
      List<dynamic> bookings = response.data['data'] ?? response.data ?? [];
      
      // Filtrar por status se fornecido
      if (status != null) {
        bookings = bookings.where((b) => b['status'] == status).toList();
      }
      
      return {'success': true, 'data': {'bookings': bookings}};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id
      final response = await _dio.get('/bookings/$id');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> confirmBooking(String bookingId) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/status
      final response = await _dio.put('/bookings/$bookingId/status', data: {'status': 'confirmed'});
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/status
      final response = await _dio.put('/bookings/$bookingId/status', data: {
        'status': 'cancelled',
        'reason': reason,
      });
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> suggestNewTime(String bookingId, String suggestedDate, String reason) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/status com status específico
      final response = await _dio.put('/bookings/$bookingId/status', data: {
        'status': 'suggested_time',
        'suggested_date': suggestedDate,
        'reason': reason,
      });
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startService(String bookingId) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/start
      final response = await _dio.put('/bookings/$bookingId/start');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> finishService(String bookingId) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/finish
      final response = await _dio.put('/bookings/$bookingId/finish');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeService(String bookingId) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/finish (mesmo que finishService)
      final response = await _dio.put('/bookings/$bookingId/finish');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // SERVICES - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getServices() async {
    try {
      await loadToken();
      // Usar endpoint real: /services
      final response = await _dio.get('/services');
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getWorkshopServices(String workshopId) async {
    try {
      await loadToken();
      // Usar endpoint real: /workshop/:id/services
      final response = await _dio.get('/workshop/$workshopId/services');
      final raw = response.data['data'] ?? response.data ?? [];
      final services = _extractServicesList(raw);
      return {'success': true, 'data': {'services': services}};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMyServices() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      return await getWorkshopServices(workshopId);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getMasterServices() async {
    final response = await getServices();
    if (response['success'] != true) {
      return response;
    }

    final raw = response['data'];
    final services = _extractServicesList(raw);
    return {'success': true, 'data': {'services': services}};
  }

  List<Map<String, dynamic>> _extractServicesList(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is Map) {
      if (raw.containsKey('services')) {
        return _extractServicesList(raw['services']);
      }
      // Alguns endpoints podem retornar um mapa com IDs como chaves
      final values = raw.values
          .where((value) => value is Map)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList();
      if (values.isNotEmpty) {
        return values;
      }
    }

    return [];
  }

  Map<String, dynamic>? _normalizeAddress(dynamic raw) {
    if (raw == null) return null;
    if (raw is Map<String, dynamic>) {
      return Map<String, dynamic>.from(raw);
    }

    if (raw is String) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map<String, dynamic>) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {
        return {'raw': raw};
      }
    }

    return {'raw': raw.toString()};
  }

  Future<Map<String, dynamic>> addService({
    required String title,
    required double price,
    required int durationMinutes,
    String? description,
    String? thumbnail,
  }) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      // A API não tem endpoint específico para adicionar serviço à oficina
      // Retornar erro informando que precisa ser implementado na API
      return {'success': false, 'error': 'Endpoint de adicionar serviço não implementado na API'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateService({
    required String serviceId,
    bool? isActive,
    double? price,
    int? durationMinutes,
    String? description,
  }) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      final data = <String, dynamic>{};
      if (isActive != null) data['is_active'] = isActive;
      if (price != null) data['price'] = price;
      if (durationMinutes != null) data['duration_minutes'] = durationMinutes;
      if (description != null) data['description'] = description;
      
      // Usar endpoint real: /services/:id
      final response = await _dio.put('/services/$serviceId', data: data);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // WORKSHOPS - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getWorkshops() async {
    try {
      await loadToken();
      // Usar endpoint real: /workshop
      final response = await _dio.get('/workshop');
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // DASHBOARD - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getWorkshopDashboard() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Buscar agendamentos da oficina e calcular métricas
      final bookingsResponse = await getMyBookings();
      if (!bookingsResponse['success']) {
        return bookingsResponse;
      }
      
      final bookings = bookingsResponse['data']?['bookings'] as List? ?? [];
      
      // Calcular métricas reais
      final totalBookings = bookings.length;
      final pendingBookings = bookings.where((b) => b['status'] == 'pendente_oficina' || b['status'] == 'pending').length;
      final confirmedBookings = bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'in_progress').length;
      final completedBookings = bookings.where((b) => b['status'] == 'completed' || b['status'] == 'finished').length;
      
      // Calcular receita mensal (dos bookings completados)
      final now = DateTime.now();
      final monthlyBookings = bookings.where((b) {
        if (b['status'] != 'completed' && b['status'] != 'finished') return false;
        final completedAt = b['completed_at'] ?? b['appointment_date'];
        if (completedAt == null) return false;
        final date = DateTime.parse(completedAt.toString());
        return date.month == now.month && date.year == now.year;
      }).toList();
      
      double monthlyRevenue = 0.0;
      for (var booking in monthlyBookings) {
        final price = booking['final_price'] ?? booking['estimated_price'] ?? 0;
        monthlyRevenue += (price is num ? price.toDouble() : 0.0);
      }
      
      return {
        'success': true,
        'data': {
          'total_bookings': totalBookings,
          'pending_bookings': pendingBookings,
          'confirmed_bookings': confirmedBookings,
          'completed_bookings': completedBookings,
          'monthly_revenue': monthlyRevenue,
        }
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // FINANCIAL - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getFinancialSummary() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Buscar agendamentos completados para calcular receita
      final bookingsResponse = await getMyBookings();
      if (!bookingsResponse['success']) {
        return bookingsResponse;
      }
      
      final bookings = bookingsResponse['data']?['bookings'] as List? ?? [];
      final completedBookings = bookings.where((b) => 
        b['status'] == 'completed' || b['status'] == 'finished'
      ).toList();
      
      // Calcular receitas
      double totalRevenue = 0.0;
      double monthlyRevenue = 0.0;
      double pendingPayments = 0.0;
      double completedPayments = 0.0;
      
      final now = DateTime.now();
      for (var booking in completedBookings) {
        final price = booking['final_price'] ?? booking['estimated_price'] ?? 0;
        final priceValue = price is num ? price.toDouble() : 0.0;
        
        totalRevenue += priceValue;
        
        // Verificar se é do mês atual
        final completedAt = booking['completed_at'] ?? booking['appointment_date'];
        if (completedAt != null) {
          try {
            final date = DateTime.parse(completedAt.toString());
            if (date.month == now.month && date.year == now.year) {
              monthlyRevenue += priceValue;
            }
          } catch (e) {
            // Ignorar erro de parsing
          }
        }
        
        // Verificar status de pagamento
        final paymentStatus = booking['payment_status'] ?? 'pending';
        if (paymentStatus == 'pending' || paymentStatus == 'pending') {
          pendingPayments += priceValue;
        } else if (paymentStatus == 'paid' || paymentStatus == 'completed') {
          completedPayments += priceValue;
        }
      }
      
      return {
        'success': true,
        'data': {
          'total_revenue': totalRevenue,
          'monthly_revenue': monthlyRevenue,
          'pending_payments': pendingPayments,
          'completed_payments': completedPayments,
        }
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // NOTIFICATIONS - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.get('/workshop/$workshopId/notifications');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.put('/workshop/$workshopId/notifications/$notificationId/read');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // SCHEDULE - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getSchedule() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/schedule
      final response = await _dio.get('/workshop/$workshopId/schedule');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateSchedule(Map<String, dynamic> scheduleData) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      final payload = {
        'schedule': scheduleData,
      };
      final response = await _dio.put('/workshop/$workshopId/schedule', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // BANKING - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getBanking() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/banking
      final response = await _dio.get('/workshop/$workshopId/banking');
      print('DEBUG: getBanking response: ${response.data}');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateBanking(Map<String, dynamic> bankingData) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Mapear campos para o formato esperado pela API
      // Priorizar os campos que a API espera diretamente
      final bankCode = bankingData['bank_code']?.toString().trim();
      final agency = (bankingData['agency'] ?? bankingData['agency_number'])?.toString().trim();
      final account = (bankingData['account'] ?? bankingData['account_number'])?.toString().trim();
      final accountType = bankingData['account_type']?.toString().trim() ?? 'checking';
      
      // Validar que os campos obrigatórios não estão vazios
      if (bankCode == null || bankCode.isEmpty) {
        return {'success': false, 'error': 'Código do banco é obrigatório'};
      }
      if (agency == null || agency.isEmpty) {
        return {'success': false, 'error': 'Agência é obrigatória'};
      }
      if (account == null || account.isEmpty) {
        return {'success': false, 'error': 'Número da conta é obrigatório'};
      }
      
      final apiData = {
        'bank_code': bankCode,
        'agency': agency,
        'account': account,
        'account_type': accountType,
      };
      
      print('DEBUG: Enviando dados bancários para API: $apiData');
      
      // Usar endpoint real: /workshop/:id/banking
      final response = await _dio.put('/workshop/$workshopId/banking', data: apiData);
      
      print('DEBUG: Resposta da API: ${response.data}');
      
      // Aguardar um pouco para garantir que o banco foi atualizado
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Após salvar, buscar novamente para confirmar
      final verifyResponse = await _dio.get('/workshop/$workshopId/banking');
      print('DEBUG: Verificação após salvar: ${verifyResponse.data}');
      
      return {'success': true, 'data': verifyResponse.data['data'] ?? verifyResponse.data};
    } catch (e) {
      print('DEBUG: Erro ao atualizar dados bancários: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // LOGO/FACADE - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> uploadLogo(String filePath) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/logo
      final formData = FormData.fromMap({
        'logo': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/workshop/$workshopId/logo', data: formData);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadFacade(String filePath) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/facade
      final formData = FormData.fromMap({
        'facade': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/workshop/$workshopId/facade', data: formData);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // EVIDENCE - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getBookingEvidence(String bookingId) async {
    try {
      await loadToken();
      // Usar endpoint real: /booking/:id/evidence
      final response = await _dio.get('/booking/$bookingId/evidence');
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
    } catch (e) {
      // Se não existir, retornar lista vazia (não mock, apenas fallback)
      return {'success': true, 'data': []};
    }
  }

  // ============================================
  // BANKING - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getBankAccount() async {
    try {
      await loadToken();
      return await getBanking();
    } catch (e) {
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
    String? pixKey,
    String? pixKeyType,
    String? bankCode,
    String? cep,
    String? street,
    String? number,
    String? neighborhood,
    String? city,
    String? state,
    String? complement,
  }) async {
    final bankingData = {
      'bank_code': bankCode ?? bankName,
      'bank_name': bankName,
      'account_type': accountType,
      'account_number': accountNumber,
      'agency_number': agencyNumber,
      'account': accountNumber,
      'agency': agencyNumber,
      'account_holder_name': accountHolderName,
      'account_holder_document': accountHolderDocument,
      if (pixKey != null && pixKey.isNotEmpty) 'pix_key': pixKey,
      if (pixKeyType != null && pixKeyType.isNotEmpty) 'pix_key_type': pixKeyType,
      if (cep != null && cep.isNotEmpty) 'bank_cep': cep,
      if (street != null && street.isNotEmpty) 'bank_street': street,
      if (number != null && number.isNotEmpty) 'bank_number': number,
      if (neighborhood != null && neighborhood.isNotEmpty) 'bank_neighborhood': neighborhood,
      if (city != null && city.isNotEmpty) 'bank_city': city,
      if (state != null && state.isNotEmpty) 'bank_state': state,
      if (complement != null && complement.isNotEmpty) 'bank_complement': complement,
    };
    try {
      await loadToken();
      return await updateBanking(bankingData);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // PAGBANK - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getPagBankAccount() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.get('/workshop/$workshopId/pagbank');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // WORKSHOP PROFILE - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getWorkshopProfile() async {
    try {
      await loadToken();
      return await getProfile();
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> updateWorkshopProfile(Map<String, dynamic> profileData) async {
    try {
      await loadToken();
      return await updateProfile(profileData);
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // NEARBY WORKSHOPS - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> getNearbyWorkshops(double lat, double lng) async {
    try {
      await loadToken();
      // Usar endpoint real: /workshop/nearby com parâmetros de geolocalização
      final response = await _dio.get('/workshop/nearby', queryParameters: {'lat': lat, 'lng': lng});
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // IMAGES - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> uploadImage({
    required String imageData,
    String? imageType,
    String? serviceId,
  }) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/logo ou similar
      final formData = FormData.fromMap({
        'image': imageData,
        if (imageType != null) 'type': imageType,
        if (serviceId != null) 'service_id': serviceId,
      });
      
      final response = await _dio.post('/workshop/$workshopId/logo', data: formData);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getImages({
    String? imageType,
    String? serviceId,
  }) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/images
      final queryParams = <String, dynamic>{};
      if (imageType != null) queryParams['type'] = imageType;
      if (serviceId != null) queryParams['service_id'] = serviceId;
      
      final response = await _dio.get('/workshop/$workshopId/images', queryParameters: queryParams);
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
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
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint real: /workshop/:id/images
      final data = <String, dynamic>{
        'type': imageType,
        if (imageIndex != null) 'index': imageIndex,
        if (serviceId != null) 'service_id': serviceId,
      };
      
      final response = await _dio.delete('/workshop/$workshopId/images', data: data);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> uploadBookingEvidence(String bookingId, dynamic file) async {
    try {
      await loadToken();
      // Usar endpoint real: /booking/:id/evidence
      String filePath;
      if (file is String) {
        filePath = file;
      } else if (file is File) {
        filePath = file.path;
      } else {
        return {'success': false, 'error': 'Tipo de arquivo inválido'};
      }
      
      final formData = FormData.fromMap({
        'evidence': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/booking/$bookingId/evidence', data: formData);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // WORKSHOP SERVICES MANAGEMENT - DADOS REAIS DA API EC2 AWS
  // ============================================

  Future<Map<String, dynamic>> addServiceToWorkshop(
    String workshopId,
    String serviceId, {
    double? price,
    int? duration,
  }) async {
    try {
      await loadToken();
      
      // Usar endpoint real: POST /workshop/:id/services
      final payload = <String, dynamic>{
        'service_id': serviceId,
      };
      if (price != null) payload['price'] = price;
      if (duration != null) payload['duration'] = duration;

      final response = await _dio.post('/workshop/$workshopId/services', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeServiceFromWorkshop(String workshopId, String serviceId) async {
    try {
      await loadToken();
      
      // Usar endpoint real: DELETE /workshop/:id/services/:serviceId
      final response = await _dio.delete('/workshop/$workshopId/services/$serviceId');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }
}
