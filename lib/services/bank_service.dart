import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class BankService {
  static String get baseUrl => AppConfig.apiBaseUrl;
  final Dio _dio = Dio();
  String? _token;

  BankService() {
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
        print('Bank Service Error: ${error.message}');
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

  // Método para atualizar dados bancários com campo de parcelamento
  Future<Map<String, dynamic>> updateBankDetails({
    required String bankName,
    required String agencia,
    required String conta,
    required String accountType,
    bool acceptsInstallment = false,
  }) async {
    try {
      await loadToken();
      
      final bankData = {
        'bank_name': bankName,
        'agencia': agencia,
        'conta': conta,
        'account_type': accountType,
        'accepts_installment': acceptsInstallment,
      };

      final response = await _dio.put('/store/workshops/me/bank-details', data: bankData);
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro ao atualizar dados bancários'};
      }
    } catch (e) {
      print('Bank Service Error updateBankDetails: $e');
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }

  // Método para obter dados bancários
  Future<Map<String, dynamic>> getBankDetails() async {
    try {
      await loadToken();
      
      final response = await _dio.get('/store/workshops/me/bank-details');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro ao obter dados bancários'};
      }
    } catch (e) {
      print('Bank Service Error getBankDetails: $e');
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }
}







