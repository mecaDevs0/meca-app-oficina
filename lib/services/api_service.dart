import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';
import 'image_service.dart';

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
    _dio.options.headers['Accept-Encoding'] = 'gzip';

    // Carregar token na inicialização
    loadToken();
    
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token == null || _token!.isEmpty) {
          await loadToken();
        }
        if (_token != null && _token!.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        return handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          saveToken('');
        }
        // Retry único para GET em erro de rede/timeout (reduz travamento em rede instável)
        final isRetryable = error.requestOptions.extra['_retry'] != true &&
            (error.type == DioExceptionType.connectionTimeout ||
                error.type == DioExceptionType.receiveTimeout ||
                error.type == DioExceptionType.connectionError) &&
            error.requestOptions.method == 'GET';
        if (isRetryable) {
          error.requestOptions.extra['_retry'] = true;
          await Future.delayed(const Duration(milliseconds: 800));
          try {
            final response = await _dio.fetch(error.requestOptions);
            return handler.resolve(response);
          } catch (e) {
            return handler.next(error);
          }
        }
        return handler.next(error);
      },
    ));
  }

  Future<Map<String, dynamic>> _handleAuthResponse(
    Response response, {
    String fallbackError = 'Erro ao autenticar',
  }) async {
    final payload = response.data;
    if (payload != null && payload['success'] == true) {
      final token = payload['data']?['token'] ?? payload['token'];
      if (token is String && token.isNotEmpty) {
        await saveToken(token);
      }
      return {'success': true, 'data': payload['data'] ?? payload};
    }
    final errorMessage = _extractErrorMessage(payload, fallbackError);
    return {'success': false, 'error': errorMessage};
  }

  String _extractErrorMessage(dynamic payload, String fallback) {
    if (payload is Map && payload['error'] != null) {
      return payload['error'].toString();
    }
    return fallback;
  }

  Future<void> loadToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('auth_token');
      
      if (_token != null && _token!.isNotEmpty) {
        _dio.options.headers['Authorization'] = 'Bearer $_token';
        // Decodificar JWT para obter workshopId
        _workshopId = _decodeJWT(_token!);
      } else {
        _dio.options.headers.remove('Authorization');
        _workshopId = null;
      }
    } catch (e) {
      _token = null;
      _workshopId = null;
      _dio.options.headers.remove('Authorization');
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
      
      // Retornar workshopId ou userId (a API pode usar qualquer one)
      return payloadMap['workshopId'] ?? payloadMap['userId'] ?? payloadMap['id'];
    } catch (e) {
      return null;
    }
  }

  // Obter workshopId atual (do token ou cache)
  Future<String?> getWorkshopId() async {
    // Se já tem em cache, retornar
    if (_workshopId != null && _workshopId!.isNotEmpty) return _workshopId;
    
    // Carregar token
    await loadToken();
    if (_token == null || _token!.isEmpty) return null;
    
    // Tentar decodificar do token primeiro
    _workshopId = _decodeJWT(_token!);
    if (_workshopId != null && _workshopId!.isNotEmpty) return _workshopId;
    
    // Se ainda não tem workshopId, tentar buscar do perfil
    try {
      final profile = await getProfile();
      if (profile['success'] && profile['data'] != null) {
        _workshopId = profile['data']['id'] as String?;
        if (_workshopId != null && _workshopId!.isNotEmpty) {
          return _workshopId;
        }
      }
    } catch (e) {
      // Erro silencioso
    }
    
    return null;
  }

  Future<void> saveToken(String token) async {
    _token = token.isNotEmpty ? token : null;
    _workshopId = token.isNotEmpty ? _decodeJWT(token) : null;
    final prefs = await SharedPreferences.getInstance();
    
    if (token.isNotEmpty) {
      await prefs.setString('auth_token', token);
      _dio.options.headers['Authorization'] = 'Bearer $token';
    } else {
      await prefs.remove('auth_token');
      _dio.options.headers.remove('Authorization');
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
      final referralCode = data['referral_code']?.toString().trim();
      if (referralCode != null && referralCode.isNotEmpty) {
        requestData['referral_code'] = referralCode;
      }
      
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
      
      // Log dos dados que serão enviados para a API
      print('📤 [API] Enviando para /auth/workshop/register:');
      print('  - email: ${requestData['email']}');
      print('  - name: ${requestData['name']}');
      print('  - cnpj: ${requestData['cnpj']}');
      print('  - phone: ${requestData['phone']}');
      print('  - address: ${requestData['address']}');
      print('  - city: ${requestData['city']}');
      print('  - state: ${requestData['state']}');
      print('  - cep: ${requestData['cep']}');
      print('  - password length: ${requestData['password']?.length ?? 0}');
      if (requestData['referral_code'] != null) {
        print('  - referral_code: ${requestData['referral_code']}');
      }
      
      final response = await _dio.post('/auth/workshop/register', data: requestData);
      
      print('📥 [API] Resposta recebida:');
      print('  - Status: ${response.statusCode}');
      print('  - Success: ${response.data['success']}');
      print('  - Error: ${response.data['error']}');
      
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
        
        // Tentar extrair mensagem de erro de diferentes formatos
        if (errorData is Map) {
          if (errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else if (errorData['message'] != null) {
            errorMessage = errorData['message'].toString();
          } else if (errorData['errors'] != null && errorData['errors'] is List) {
            errorMessage = (errorData['errors'] as List).join(', ');
          } else if (errorData['errors'] != null && errorData['errors'] is Map) {
            errorMessage = (errorData['errors'] as Map).values.join(', ');
          }
        }
        
        // Mensagens específicas por status code
        if (statusCode == 404) {
          errorMessage = 'Endpoint não encontrado. Verifique a URL da API.';
        } else if (statusCode == 400 && errorMessage == 'Erro ao registrar oficina') {
          // Se não conseguiu extrair mensagem específica, tentar mais uma vez
          if (errorData is Map) {
            errorMessage = errorData.toString().contains('CNPJ') 
                ? 'CNPJ inválido ou já cadastrado. Verifique os dados.'
                : errorData.toString().contains('email') || errorData.toString().contains('Email')
                    ? 'Email inválido ou já cadastrado. Verifique os dados.'
                    : 'Dados inválidos. Verifique se todos os campos obrigatórios estão preenchidos corretamente.';
          } else {
            errorMessage = 'Dados inválidos. Verifique se todos os campos obrigatórios estão preenchidos corretamente.';
          }
        } else if (statusCode == 500) {
          errorMessage = 'Erro interno do servidor. Tente novamente mais tarde.';
        } else if (statusCode != null && statusCode != 400 && errorMessage == 'Erro ao registrar oficina') {
          errorMessage = 'Erro ${statusCode}: ${errorData?.toString() ?? e.message}';
        }
      } else if (e.type == DioExceptionType.connectionTimeout ||
                 e.type == DioExceptionType.receiveTimeout ||
                 e.type == DioExceptionType.connectionError) {
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

  /// Timeout do login (evita ficar carregando para sempre se API/rede travar)
  static const int loginTimeoutSeconds = 25;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio
          .post('/auth/workshop/login', data: {
            'email': email.trim(),
            'password': password,
          })
          .timeout(Duration(seconds: loginTimeoutSeconds));

      return await _handleAuthResponse(
        response,
        fallbackError: 'Erro ao fazer login',
      );
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        return {
          'success': false,
          'error': 'Tempo esgotado ou sem conexão. Verifique a internet e tente novamente.',
        };
      }
      final message = _extractErrorMessage(e.response?.data, 'Erro ao fazer login');
      return {'success': false, 'error': message};
    } catch (e) {
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        return {'success': false, 'error': 'Tempo esgotado. Verifique sua conexão e tente novamente.'};
      }
      return {'success': false, 'error': 'Erro ao conectar. Tente novamente.'};
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
  // DEVICE TOKENS - PUSH NOTIFICATIONS
  // ============================================

  Future<Map<String, dynamic>> saveDeviceToken(String onesignalPlayerId, {String? platform}) async {
    try {
      await loadToken();
      
      final response = await _dio.post('/device-tokens', data: {
        'onesignal_player_id': onesignalPlayerId,
        'platform': platform ?? (Platform.isAndroid ? 'android' : 'ios'),
      });
      
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      if (e is DioException) {
        return {'success': false, 'error': e.response?.data['error'] ?? 'Erro ao salvar token'};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> removeDeviceToken(String onesignalPlayerId) async {
    try {
      await loadToken();
      
      final response = await _dio.delete('/device-tokens', data: {
        'onesignal_player_id': onesignalPlayerId,
      });
      
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      if (e is DioException) {
        return {'success': false, 'error': e.response?.data['error'] ?? 'Erro ao remover token'};
      }
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<SharedPreferences> getStorage() async {
    return await SharedPreferences.getInstance();
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

  // PASSO 15: Buscar pagamento por booking_id
  Future<Map<String, dynamic>> getPaymentByBooking(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.get('/bookings/$bookingId/payment');
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao buscar pagamento'};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> getBookingDetails(String bookingId, {bool forceRefresh = false}) async {
    try {
      await loadToken();
      
      if (_token == null || _token!.isEmpty) {
        return {'success': false, 'error': 'Token de autenticação não encontrado. Faça login novamente.'};
      }
      
      // IMPORTANTE: Se forceRefresh, adicionar timestamp para forçar nova requisição (bypass cache)
      final url = forceRefresh 
          ? '/bookings/$bookingId?_t=${DateTime.now().millisecondsSinceEpoch}'
          : '/bookings/$bookingId';
      
      final response = await _dio.get(url);
      
      if (response.data != null && response.data['success'] == true) {
        final data = response.data['data'];
        
        // Garantir que data é um Map, não uma List
        Map<String, dynamic> bookingData;
        if (data is List && data.isNotEmpty) {
          bookingData = Map<String, dynamic>.from(data[0]);
        } else if (data is Map) {
          bookingData = Map<String, dynamic>.from(data);
        } else {
          return {'success': false, 'error': 'Formato de dados inválido'};
        }
        
        return {'success': true, 'data': bookingData};
      } else {
        return {'success': false, 'error': response.data?['error'] ?? 'Erro ao buscar agendamento'};
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        // Token inválido ou expirado
        await saveToken('');
        return {'success': false, 'error': 'Sessão expirada. Faça login novamente.', 'unauthorized': true};
      }
      
      return {'success': false, 'error': e.response?.data?['error'] ?? e.message ?? 'Erro ao buscar agendamento'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

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
      
      // Filtrar por status se fornecido (mapeando sinônimos)
      if (status != null) {
        final target = status.toString().toLowerCase().trim();
        bookings = bookings.where((b) {
          final s = (b['status'] ?? '').toString().toLowerCase().trim();
          
          if (target == 'pendente_oficina' || target == 'pending') {
            return s == 'pending' ||
                s == 'pendente' ||
                s == 'pendente_oficina' ||
                s == 'pending_oficina';
          }
          
          if (target == 'confirmado' || target == 'confirmed') {
            return s == 'confirmed' ||
                s == 'confirmado' ||
                s == 'started' ||
                s == 'in_progress' ||
                s == 'em_andamento';
          }
          
          if (target == 'concluido' || target == 'completed') {
            return s == 'completed' ||
                s == 'finished' ||
                s == 'concluido' ||
                s == 'concluído' ||
                s == 'finalizado_aguardando_pagamento' ||
                s == 'pago' ||
                s == 'paid' ||
                s == 'approved';
          }
          
          if (target == 'pendente_cliente' || target == 'pending_client') {
            return s == 'pendente_cliente';
          }
          
          return s == target;
        }).toList();
      }
      
      final normalized = bookings
          .whereType<Map>()
          .map((e) => _normalizeBooking(Map<String, dynamic>.from(e)))
          .toList();

      normalized.sort((a, b) =>
          (a['sort_timestamp'] ?? 0).compareTo(b['sort_timestamp'] ?? 0));

      return {'success': true, 'data': {'bookings': normalized}};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getBookingById(String id) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id
      final response = await _dio.get('/bookings/$id');
      final rawData = response.data['data'] ?? response.data;

      if (rawData is List && rawData.isNotEmpty) {
        return {
          'success': true,
          'data': _normalizeBooking(
            Map<String, dynamic>.from(rawData.first as Map),
          ),
        };
      }

      if (rawData is Map) {
        return {
          'success': true,
          'data': _normalizeBooking(Map<String, dynamic>.from(rawData)),
        };
      }

      return {'success': false, 'error': 'Agendamento não encontrado'};
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

  Future<Map<String, dynamic>> checkInVehicle(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.put('/bookings/$bookingId/check-in', data: {});
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?.toString() ??
          e.message ??
          'Erro ao fazer check-in do veículo';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> rejectBooking(String bookingId, String reason) async {
    try {
      await loadToken();
      // Usar endpoint real: /bookings/:id/cancel
      final response = await _dio.put('/bookings/$bookingId/cancel', data: {
        'reason': reason,
      });
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data'] ?? response.data};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao recusar agendamento'};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> suggestNewTime(String bookingId, String suggestedDate, String reason) async {
    try {
      await loadToken();
      final response = await _dio.put('/bookings/$bookingId/suggest-time', data: {
        'suggested_date': suggestedDate,
        'reason': reason,
      });
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao sugerir horário'};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String bookingId, {String? reason}) async {
    try {
      await loadToken();
      final response = await _dio.put('/bookings/$bookingId/cancel', data: {
        if (reason != null) 'reason': reason,
      });
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'data': response.data['data']};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao cancelar agendamento'};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  Future<Map<String, dynamic>> startService(
    String bookingId, {
    int? estimatedPriceCents,
  }) async {
    try {
      await loadToken();
      final payload = <String, dynamic>{};
      if (estimatedPriceCents != null) {
        payload['estimatedPrice'] = estimatedPriceCents;
      }
      final response = await _dio.put('/bookings/$bookingId/start', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?.toString() ?? 
                          e.message ?? 
                          'Erro ao iniciar o serviço';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Inicia o serviço mas deixa pendente aguardando confirmação do cliente
  Future<Map<String, dynamic>> startServicePending(
    String bookingId, {
    int? estimatedPriceCents,
  }) async {
    try {
      await loadToken();
      final payload = <String, dynamic>{};
      if (estimatedPriceCents != null) {
        payload['estimatedPrice'] = estimatedPriceCents;
      }
      final response = await _dio.put('/bookings/$bookingId/start-pending', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?.toString() ?? 
                          e.message ?? 
                          'Erro ao iniciar o serviço';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> sendQuote(
    String bookingId, {
    int? finalPriceCents, // Formato antigo (compatibilidade)
    List<Map<String, dynamic>>? items, // Novo formato
    int? diagnosticValueCents, // Novo formato
    String? quoteReason, // Motivo do orçamento
  }) async {
    try {
      await loadToken();
      final payload = <String, dynamic>{};
      
      // Suporte para formato antigo e novo
      if (items != null && items.isNotEmpty) {
        // Novo formato: items + diagnóstico
        payload['items'] = items;
        if (diagnosticValueCents != null && diagnosticValueCents > 0) {
          payload['diagnosticValue'] = diagnosticValueCents;
        }
      } else if (finalPriceCents != null) {
        // Formato antigo: apenas finalPrice
        payload['finalPrice'] = finalPriceCents;
      } else {
        return {'success': false, 'error': 'Informe items do orçamento ou valor final'};
      }
      
      // Adicionar quoteReason se fornecido
      if (quoteReason != null && quoteReason.trim().isNotEmpty) {
        payload['quoteReason'] = quoteReason.trim();
      }
      
      final response = await _dio.put('/bookings/$bookingId/send-quote', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?.toString() ?? 
                          e.message ?? 
                          'Erro ao enviar orçamento';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> editQuote(
    String bookingId, {
    required List<Map<String, dynamic>> items,
    int? diagnosticValueCents,
    String? quoteReason, // Motivo do orçamento
  }) async {
    try {
      await loadToken();
      final payload = <String, dynamic>{
        'items': items,
      };
      if (diagnosticValueCents != null && diagnosticValueCents > 0) {
        payload['diagnosticValue'] = diagnosticValueCents;
      }
      
      // Adicionar quoteReason se fornecido
      if (quoteReason != null && quoteReason.trim().isNotEmpty) {
        payload['quoteReason'] = quoteReason.trim();
      }
      
      final response = await _dio.put('/bookings/$bookingId/edit-quote', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['error']?.toString() ?? 
                          e.message ?? 
                          'Erro ao editar orçamento';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> finishService(
    String bookingId, {
    int? finalPriceCents, // Formato antigo (compatibilidade)
    List<Map<String, dynamic>>? items, // Novo formato
    int? diagnosticValueCents, // Novo formato
    String? notes,
    String? quoteReason, // Motivo do orçamento
  }) async {
    try {
      await loadToken();
      final payload = <String, dynamic>{};
      
      // Suporte para formato antigo e novo
      if (items != null && items.isNotEmpty) {
        // Novo formato: items + diagnóstico
        payload['items'] = items;
        if (diagnosticValueCents != null && diagnosticValueCents > 0) {
          payload['diagnosticValue'] = diagnosticValueCents;
        }
      } else if (finalPriceCents != null) {
        // Formato antigo: apenas finalPrice
        payload['finalPrice'] = finalPriceCents;
      } else {
        return {'success': false, 'error': 'Informe items do orçamento ou valor final'};
      }
      
      if (notes != null && notes.trim().isNotEmpty) {
        payload['notes'] = notes.trim();
      }
      
      // Adicionar quoteReason se fornecido
      if (quoteReason != null && quoteReason.trim().isNotEmpty) {
        payload['quoteReason'] = quoteReason.trim();
      }
      
      final response = await _dio.put('/bookings/$bookingId/finish', data: payload);
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
      // A API retorna { success: true, data: [...] } onde data é um array direto
      final raw = response.data['data'] ?? response.data ?? [];
      final services = _extractServicesList(raw);
      // Retornar no formato esperado pelo provider
      return {'success': true, 'data': services};
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

  List<Map<String, dynamic>> _extractUploadsList(dynamic raw) {
    if (raw == null) return [];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    }

    if (raw is Map) {
      if (raw.containsKey('data')) {
        return _extractUploadsList(raw['data']);
      }
      if (raw.containsKey('customer_uploads')) {
        return _extractUploadsList(raw['customer_uploads']);
      }
      if (raw.containsKey('uploads')) {
        return _extractUploadsList(raw['uploads']);
      }
      if (raw.containsKey('evidence')) {
        return _extractUploadsList(raw['evidence']);
      }
      final nested = raw.values
          .where((value) => value is Map || value is List)
          .expand((value) => _extractUploadsList(value))
          .toList();
      if (nested.isNotEmpty) {
        return nested;
      }
    }

    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        return _extractUploadsList(decoded);
      } catch (_) {
        return [];
      }
    }

    return [];
  }

  DateTime? _parseDate(dynamic raw) {
    if (raw == null) return null;

    if (raw is DateTime) {
      return raw;
    }

    if (raw is int) {
      try {
        // Assume timestamp em milissegundos
        return DateTime.fromMillisecondsSinceEpoch(raw, isUtc: false);
      } catch (_) {
        return null;
      }
    }

    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
        return null;
      }
      try {
        return DateTime.parse(trimmed).toLocal();
      } catch (_) {
        // Tentar adicionar 'Z' se faltar timezone
        try {
          return DateTime.parse('${trimmed}Z').toLocal();
        } catch (_) {
          return null;
        }
      }
    }

    return null;
  }

  String _composeCustomerName({
    String? first,
    String? last,
    String? fallback,
  }) {
    final buffer = StringBuffer();
    if (first != null && first.trim().isNotEmpty) {
      buffer.write(first.trim());
    }
    if (last != null && last.trim().isNotEmpty) {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(last.trim());
    }
    if (buffer.isEmpty && fallback != null && fallback.trim().isNotEmpty) {
      buffer.write(fallback.trim());
    }
    final name = buffer.isEmpty ? 'Cliente MECA' : buffer.toString();
    return name[0].toUpperCase() + name.substring(1);
  }

  String _composeVehicleLabel({String? brand, String? model, String? plate}) {
    final parts = <String>[];
    if (brand != null && brand.trim().isNotEmpty) {
      parts.add(brand.trim());
    }
    if (model != null && model.trim().isNotEmpty) {
      parts.add(model.trim());
    }
    final base = parts.isEmpty ? 'Veículo' : parts.join(' ');
    if (plate != null && plate.trim().isNotEmpty) {
      return '$base • ${plate.trim().toUpperCase()}';
    }
    return base;
  }

  Map<String, dynamic> _normalizeBooking(Map<String, dynamic> original) {
    final booking = Map<String, dynamic>.from(original);

    final customerMap = booking['customer'] is Map
        ? Map<String, dynamic>.from(booking['customer'] as Map)
        : <String, dynamic>{};

    final firstName = booking['customer_first_name'] ??
        customerMap['first_name'] ??
        booking['customer_name'] ??
        customerMap['name'];
    final lastName = booking['customer_last_name'] ?? customerMap['last_name'];
    final fallbackName = booking['customer_name'] ?? customerMap['full_name'];

    booking['customer_first_name'] = firstName;
    booking['customer_last_name'] = lastName;
    booking['customer_name'] =
        _composeCustomerName(first: firstName?.toString(), last: lastName?.toString(), fallback: fallbackName?.toString());
    booking['customer_phone'] = booking['customer_phone'] ??
        customerMap['phone'] ??
        customerMap['phone_number'] ??
        customerMap['mobile'];
    booking['customer_email'] = booking['customer_email'] ?? customerMap['email'];

    final vehicleMap = booking['vehicle'] is Map
        ? Map<String, dynamic>.from(booking['vehicle'] as Map)
        : <String, dynamic>{};
    final vehicleBrand = booking['vehicle_brand'] ??
        vehicleMap['brand'] ??
        vehicleMap['make'] ??
        booking['brand'];
    final vehicleModel = booking['vehicle_model'] ??
        vehicleMap['model'] ??
        booking['model'];
    final vehiclePlate = booking['vehicle_plate'] ??
        vehicleMap['plate'] ??
        vehicleMap['license_plate'] ??
        booking['plate'];

    booking['vehicle_brand'] = vehicleBrand;
    booking['vehicle_model'] = vehicleModel;
    booking['vehicle_plate'] = vehiclePlate;
    booking['vehicle_display'] = _composeVehicleLabel(
      brand: vehicleBrand?.toString(),
      model: vehicleModel?.toString(),
      plate: vehiclePlate?.toString(),
    );
    // IMPORTANTE: Criar vehicle_info para compatibilidade com tela de detalhes
    // Deve incluir marca e modelo quando disponíveis
    if (vehicleBrand != null || vehicleModel != null) {
      final parts = <String>[];
      if (vehicleBrand != null) parts.add(vehicleBrand.toString());
      if (vehicleModel != null) parts.add(vehicleModel.toString());
      booking['vehicle_info'] = parts.join(' ');
    } else {
      booking['vehicle_info'] = null;
    }

    final serviceMap = booking['service'] is Map
        ? Map<String, dynamic>.from(booking['service'] as Map)
        : <String, dynamic>{};
    final servicesList = booking['services'] is List
        ? List<Map<String, dynamic>>.from(
            (booking['services'] as List)
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e)),
          )
        : <Map<String, dynamic>>[];
    final serviceName = booking['service_name'] ??
        serviceMap['name'] ??
        (servicesList.isNotEmpty
            ? (servicesList.first['name'] ??
                servicesList.first['title'] ??
                servicesList.first['service_name'])
            : null);
    booking['service_name'] = serviceName ?? 'Serviço';

    final appointment = _parseDate(
      booking['appointment_date'] ??
          booking['scheduled_date'] ??
          booking['date'] ??
          booking['appointment'],
    );
    if (appointment != null) {
      booking['appointment_date'] = appointment.toIso8601String();
      booking['sort_timestamp'] = appointment.millisecondsSinceEpoch;
    } else {
      booking['sort_timestamp'] =
          DateTime.tryParse(booking['created_at']?.toString() ?? '')?.millisecondsSinceEpoch ?? 0;
    }

    booking['customer_notes'] = booking['customer_notes'] ??
        booking['customer_observation'] ??
        booking['notes'] ??
        '';

    final uploads = _extractUploadsList(
      booking['customer_uploads'] ??
          booking['customerUploads'] ??
          booking['uploads'] ??
          booking['observations_files'],
    );
    booking['customer_uploads'] = uploads;

    return booking;
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
      final response = await _dio.get('/workshop');
      if (response.data == null || response.data['success'] != true) {
        return {'success': false, 'error': 'Erro ao buscar oficinas'};
      }
      final data = response.data['data'];
      List<dynamic> workshops = [];
      if (data is Map) {
        workshops = data['workshops'] ?? data['workshop'] ?? data['data'] ?? [];
      } else if (data is List) {
        workshops = data;
      }
      return {'success': true, 'data': workshops};
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
      final pendingBookings = bookings.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'pending' || s == 'pendente' || s == 'pendente_oficina' || s == 'pending_oficina';
      }).length;
      final confirmedBookings = bookings.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'confirmed' || s == 'confirmado' || s == 'started' || s == 'in_progress' || s == 'em_andamento';
      }).length;
      final completedBookings = bookings.where((b) {
        final s = (b['status'] ?? '').toString().toLowerCase();
        return s == 'completed' || s == 'finished' || s == 'concluido' || s == 'concluído';
      }).length;
      
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

  Future<Map<String, dynamic>> getFinancialSummary({String? startDate, String? endDate, int? limit, int? offset}) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      // Endpoint financial-summary: retorna effective_meca_fee (12%), values_to_receive, totals, metrics
      final queryParams = <String, dynamic>{};
      if (startDate != null) queryParams['startDate'] = startDate;
      if (endDate != null) queryParams['endDate'] = endDate;
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;

      final response = await _dio.get(
        '/workshop/$workshopId/financial-summary',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  /// GET /workshop/referrals - Programa Indique e Ganhe (código, contagem, taxa atual)
  Future<Map<String, dynamic>> getReferrals() async {
    try {
      await loadToken();
      final response = await _dio.get('/workshop/referrals');
      final raw = response.data;
      if (raw == null || raw['success'] != true) {
        return {'success': false, 'error': raw?['error'] ?? 'Erro ao carregar indicações'};
      }
      return {'success': true, 'data': raw['data'] ?? raw};
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

  Future<Map<String, dynamic>> markAllNotificationsAsRead() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.put('/workshop/$workshopId/notifications/read-all');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // SCHEDULE - DADOS REAIS DA API EC2 AWS
  // ============================================

  /// GET /workshop/:id/schedule - dados reais do RDS (produção)
  Future<Map<String, dynamic>> getSchedule() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      final response = await _dio.get('/workshop/$workshopId/schedule');
      final data = response.data;
      if (data == null) return {'success': false, 'error': 'Resposta inválida da API'};
      return {'success': true, 'data': data['data'] ?? data};
    } on DioException catch (e) {
      return {
        'success': false,
        'error': e.response?.data?['error'] ?? e.message ?? 'Erro ao carregar agenda',
      };
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
      final payload = {'schedule': scheduleData};
      final response = await _dio.put('/workshop/$workshopId/schedule', data: payload);
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return {'success': false, 'error': 'Endpoint de agenda indisponível. Tente novamente em instantes.'};
      }
      return {'success': false, 'error': e.response?.data?['error'] ?? 'Erro ao salvar agenda. Tente novamente.'};
    } catch (e) {
      return {'success': false, 'error': 'Erro ao salvar agenda. Tente novamente.'};
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
      
      // Usar endpoint real: /workshop/:id/banking
      await _dio.put('/workshop/$workshopId/banking', data: apiData);
      
      // Aguardar um pouco para garantir que o banco foi atualizado
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Após salvar, buscar novamente para confirmar
      final verifyResponse = await _dio.get('/workshop/$workshopId/banking');
      
      return {'success': true, 'data': verifyResponse.data['data'] ?? verifyResponse.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // ============================================
  // LOGO/FACADE - DADOS REAIS DA API EC2 AWS
  // ============================================

  // Remover logo da oficina
  Future<Map<String, dynamic>> removeLogo() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Usar endpoint DELETE: /workshop/:id/logo
      final response = await _dio.delete('/workshop/$workshopId/logo');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      final errorMessage = e.toString();
      if (errorMessage.contains('403')) {
        return {'success': false, 'error': 'Você não tem permissão para remover esta logo'};
      } else if (errorMessage.contains('404')) {
        return {'success': false, 'error': 'Oficina não encontrada'};
      }
      return {'success': false, 'error': errorMessage};
    }
  }

  // Upload de logo usando base64 (NOVO - preferido)
  Future<Map<String, dynamic>> uploadLogo(String base64DataUrl) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Validar formato base64
      if (!base64DataUrl.startsWith('data:image/')) {
        return {'success': false, 'error': 'Formato inválido. Use data:image/jpeg;base64,... ou data:image/png;base64,...'};
      }
      
      // Usar endpoint novo: /workshop/:id/logo com base64
      final response = await _dio.post(
        '/workshop/$workshopId/logo',
        data: {'logo_base64': base64DataUrl},
      );
      
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      final errorMessage = e.toString();
      // Extrair mensagem de erro mais amigável
      if (errorMessage.contains('400')) {
        return {'success': false, 'error': 'Formato de imagem inválido. Use JPG ou PNG'};
      } else if (errorMessage.contains('403')) {
        return {'success': false, 'error': 'Você não tem permissão para atualizar esta oficina'};
      } else if (errorMessage.contains('413') || errorMessage.contains('muito grande')) {
        return {'success': false, 'error': 'Imagem muito grande. Tamanho máximo: 5MB'};
      }
      return {'success': false, 'error': errorMessage};
    }
  }
  
  // Upload de logo usando file path (LEGADO - mantido para compatibilidade)
  Future<Map<String, dynamic>> uploadLogoFromFile(String filePath) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }
      
      // Converter para base64 primeiro
      final file = XFile(filePath);
      final base64String = await ImageService.fileToBase64(file);
      if (base64String == null) {
        return {'success': false, 'error': 'Erro ao converter imagem para base64'};
      }
      
      // Usar método base64
      return await uploadLogo(base64String);
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
      // Usar endpoint real: /bookings/:id/images (substitui /bookings/:id/evidence na API nova)
      final response = await _dio.get('/bookings/$bookingId/images');
      return {'success': true, 'data': response.data['data'] ?? response.data ?? []};
    } catch (e) {
      // Se não existir, retornar lista vazia (não mock, apenas fallback)
      return {'success': true, 'data': []};
    }
  }

  Future<Map<String, dynamic>> getCustomerUploads(String bookingId) async {
    try {
      await loadToken();
      final response = await _dio.get('/bookings/$bookingId/images');

      if (response.data != null && response.data['success'] == true) {
        final uploads = _extractUploadsList(response.data['data']);
        return {'success': true, 'data': uploads};
      }

      final errorMessage = response.data?['error']?.toString() ?? 'Erro ao buscar fotos do cliente.';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
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

  // POST /workshop/:id/pagbank - Atualizar pagbank_account_id (manual)
  Future<Map<String, dynamic>> updatePagBankAccountId(String? pagbankAccountId) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final payload = <String, dynamic>{'pagbank_account_id': pagbankAccountId};
      final response = await _dio.post('/workshop/$workshopId/pagbank', data: payload);
      return {
        'success': true,
        'data': response.data['data'] ?? response.data,
        'message': response.data['message'],
      };
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao atualizar PagBank Account ID';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // GET /workshop/:id/pagbank/account-status - Verificar status da conta PagBank
  Future<Map<String, dynamic>> getPagBankAccountStatus() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.get('/workshop/$workshopId/pagbank/account-status');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao verificar status da conta PagBank';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // POST /workshop/:id/pagbank/create-account - Criar conta PagBank
  Future<Map<String, dynamic>> createPagBankAccount(Map<String, dynamic> registrationData) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.post(
        '/workshop/$workshopId/pagbank/create-account',
        data: registrationData,
      );
      return {'success': true, 'data': response.data['data'] ?? response.data, 'message': response.data['message']};
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao criar conta PagBank';
      return {'success': false, 'error': errorMessage, 'needs_authorization': errorData is Map && errorData['needs_authorization'] == true};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // PUT /workshop/:id/pagbank/confirm-approval - Confirmar aprovação da conta
  Future<Map<String, dynamic>> confirmPagBankApproval() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.put('/workshop/$workshopId/pagbank/confirm-approval');
      return {'success': true, 'data': response.data['data'] ?? response.data, 'message': response.data['message']};
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao confirmar aprovação';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // GET CEP data (usando API externa viacep.com.br)
  Future<Map<String, dynamic>> getCepData(String cep) async {
    try {
      final cleanCep = cep.replaceAll(RegExp(r'[^0-9]'), '');
      if (cleanCep.length != 8) {
        return {'success': false, 'error': 'CEP inválido'};
      }

      final response = await _dio.get('https://viacep.com.br/ws/$cleanCep/json/');
      if (response.data['erro'] == true) {
        return {'success': false, 'error': 'CEP não encontrado'};
      }
      return {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> startPagBankConnect({
    String? redirectUri,
    String? scope,
  }) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final payload = <String, dynamic>{};
      if (redirectUri != null && redirectUri.isNotEmpty) {
        payload['redirectUri'] = redirectUri;
      }
      if (scope != null && scope.isNotEmpty) {
        payload['scope'] = scope;
      }

      // Adicionar timeout maior para esta requisição específica
      // Salvar timeouts originais
      final originalConnectTimeout = _dio.options.connectTimeout;
      final originalReceiveTimeout = _dio.options.receiveTimeout;
      
      try {
        // Configurar timeouts maiores temporariamente
        _dio.options.connectTimeout = const Duration(seconds: 30);
        _dio.options.receiveTimeout = const Duration(seconds: 30);
        
        final response = await _dio.post(
          '/workshop/$workshopId/pagbank/connect/start',
          // Nunca enviar null: backend pode tentar ler req.body
          data: payload,
        );
        
        return {'success': true, 'data': response.data['data'] ?? response.data};
      } catch (e) {
        // Restaurar timeouts em caso de erro também
        _dio.options.connectTimeout = originalConnectTimeout;
        _dio.options.receiveTimeout = originalReceiveTimeout;
        
        if (e is DioException) {
          final dioError = e;
          print('❌ [ApiService] Erro ao iniciar PagBank Connect: ${dioError.type}');
          print('❌ [ApiService] Mensagem: ${dioError.message}');
          print('❌ [ApiService] Response: ${dioError.response?.data}');
          
          final errorData = dioError.response?.data;
          String errorMessage;
          
          if (dioError.type == DioExceptionType.connectionTimeout) {
            errorMessage = 'Timeout de conexão. Verifique sua internet e tente novamente.';
          } else if (dioError.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Timeout ao receber resposta. Tente novamente.';
          } else if (dioError.type == DioExceptionType.connectionError) {
            errorMessage = 'Erro de conexão. Verifique se a API está online e sua internet está funcionando.';
          } else if (errorData is Map && errorData['error'] != null) {
            errorMessage = errorData['error'].toString();
          } else {
            errorMessage = dioError.message ?? 'Erro ao iniciar PagBank Connect';
          }
          
          return {'success': false, 'error': errorMessage};
        } else {
          print('❌ [ApiService] Erro inesperado: $e');
          return {'success': false, 'error': 'Erro inesperado: ${e.toString()}'};
        }
      } finally {
        // Restaurar timeouts originais
        _dio.options.connectTimeout = originalConnectTimeout;
        _dio.options.receiveTimeout = originalReceiveTimeout;
      }
    } catch (e) {
      // Erro ao carregar token ou obter workshopId
      print('❌ [ApiService] Erro ao preparar PagBank Connect: $e');
      return {'success': false, 'error': 'Erro ao preparar conexão: ${e.toString()}'};
    }
  }

  // GET /pagbank/auth-url - Obter URL de autorização OAuth2
  Future<Map<String, dynamic>> getPagBankAuthUrl({String? redirectUri}) async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final queryParams = <String, dynamic>{};
      if (redirectUri != null && redirectUri.isNotEmpty) {
        queryParams['redirect_uri'] = redirectUri;
      }
      queryParams['workshopId'] = workshopId;

      final response = await _dio.get(
        '/pagbank/auth-url',
        queryParameters: queryParams.isEmpty ? null : queryParams,
      );
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao obter URL de autorização';
      return {'success': false, 'error': errorMessage};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // POST /workshop/:id/pagbank/verify - Verificar status da conta PagBank (KYC)
  Future<Map<String, dynamic>> verifyPagBankAccount() async {
    try {
      await loadToken();
      final workshopId = await getWorkshopId();
      if (workshopId == null) {
        return {'success': false, 'error': 'Token inválido ou workshopId não encontrado'};
      }

      final response = await _dio.post('/workshop/$workshopId/pagbank/verify');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } on DioException catch (e) {
      final errorData = e.response?.data;
      final errorMessage = errorData is Map && errorData['error'] != null
          ? errorData['error'].toString()
          : e.message ?? 'Erro ao verificar conta PagBank';
      return {'success': false, 'error': errorMessage};
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
      
      // Se for logo, usar endpoint específico de logo com base64
      if (imageType == 'logo') {
        return await uploadLogo(imageData);
      }
      
      // Para outros tipos, usar endpoint genérico (se existir)
      final formData = FormData.fromMap({
        'image': imageData,
        if (imageType != null) 'type': imageType,
        if (serviceId != null) 'service_id': serviceId,
      });
      
      final response = await _dio.post('/workshop/$workshopId/images', data: formData);
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
      // Usar endpoint real: /bookings/:id/images (substitui /bookings/:id/evidence na API nova)
      String filePath;
      if (file is String) {
        filePath = file;
      } else if (file is File) {
        filePath = file.path;
      } else {
        return {'success': false, 'error': 'Tipo de arquivo inválido'};
      }
      
      final formData = FormData.fromMap({
        'image': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/bookings/$bookingId/images', data: formData);
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
      // Price e duration são opcionais - NÃO enviar campos se forem null
      final payload = <String, dynamic>{
        'service_id': serviceId,
      };
      
      // Apenas adicionar price e duration se não forem null
      if (price != null) {
        payload['price'] = price;
      }
      if (duration != null) {
        payload['duration'] = duration;
      }

      print('📤 [addServiceToWorkshop] Enviando: service_id=$serviceId, price=$price, duration=$duration');
      print('📤 [addServiceToWorkshop] Payload JSON: $payload');

      final response = await _dio.post('/workshop/$workshopId/services', data: payload);
      
      print('✅ [addServiceToWorkshop] Sucesso: ${response.data}');
      return {'success': true, 'data': response.data['data'] ?? response.data};
    } catch (e) {
      // Log detalhado para debug
      print('❌ Erro ao adicionar serviço: serviceId=$serviceId, price=$price, duration=$duration');
      print('❌ Exception: $e');
      if (e is DioException && e.response != null) {
        print('❌ Response status: ${e.response?.statusCode}');
        print('❌ Response data: ${e.response?.data}');
      }
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

  // Recuperar senha (oficina)
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/auth/workshop/forgot-password', data: {'email': email});
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message'] ?? 'Email enviado com sucesso'};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao enviar email'};
      }
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Alterar senha no perfil (oficina)
  Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await loadToken();
      final response = await _dio.put('/workshop/profile/password', data: {
        'currentPassword': currentPassword,
        'newPassword': newPassword,
      });
      
      if (response.data != null && response.data['success'] == true) {
        return {'success': true, 'message': response.data['message'] ?? 'Senha alterada com sucesso'};
      } else {
        return {'success': false, 'error': response.data['error'] ?? 'Erro ao alterar senha'};
      }
    } catch (e) {
      return {'success': false, 'error': _getErrorMessage(e)};
    }
  }

  String? _extractServerMessage(dynamic responseData) {
    if (responseData == null) return null;

    if (responseData is String) {
      return responseData;
    }

    if (responseData is List && responseData.isNotEmpty) {
      final first = responseData.first;
      if (first is String) {
        return first;
      }
      if (first is Map) {
        final map = Map<String, dynamic>.from(first);
        for (final key in ['error', 'message', 'detail', 'msg']) {
          final value = map[key];
          if (value is String && value.trim().isNotEmpty) {
            return value;
          }
        }
      }
    }

    if (responseData is Map) {
      final map = Map<String, dynamic>.from(responseData);
      for (final key in ['error', 'message', 'detail', 'msg']) {
        final value = map[key];
        if (value is String && value.trim().isNotEmpty) {
          return value;
        }
      }
    }

    return null;
  }

  String _getErrorMessage(dynamic error) {
    if (error is DioException) {
      final serverMessage = _extractServerMessage(error.response?.data);
      if (serverMessage != null && serverMessage.trim().isNotEmpty) {
        return serverMessage.trim();
      }

      switch (error.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          return 'Timeout de conexão. Verifique sua internet.';
        case DioExceptionType.badResponse:
          final statusCode = error.response?.statusCode;
          if (statusCode == 401) {
            return 'Sua sessão expirou. Entre novamente para continuar.';
          } else if (statusCode == 404) {
            return 'Não encontramos essas informações. Atualize a tela e tente novamente.';
          } else if (statusCode == 500) {
            return 'Estamos passando por uma instabilidade. Tente novamente em instantes.';
          }
          return 'Ocorreu um erro (${statusCode ?? 'indefinido'}). Tente novamente em instantes.';
        case DioExceptionType.cancel:
          return 'Requisição cancelada.';
        case DioExceptionType.connectionError:
          return 'Erro de conexão. Verifique sua internet.';
        default:
          return 'Erro de rede: ${error.message}';
      }
    }
    return 'Erro inesperado: ${error.toString()}';
  }
}
