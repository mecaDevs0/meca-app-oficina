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
    required String workshopId,
    required String bankName,
    required String agencia,
    required String conta,
    required String accountType,
    bool acceptsInstallment = false,
    String? birthDate,
    String? companyType,
    int? incomeValue,
    String? mobilePhone,
  }) async {
    try {
      await loadToken();

      final bankData = {
        'bank_name': bankName,
        'bank_code': bankName,
        'agency': agencia,
        'account': conta,
        'account_type': accountType,
        'accepts_installment': acceptsInstallment,
      };
      if (birthDate != null && birthDate.isNotEmpty) {
        bankData['birth_date'] = birthDate;
      }
      if (companyType != null && companyType.isNotEmpty) {
        bankData['company_type'] = companyType;
      }
      if (incomeValue != null && incomeValue > 0) {
        bankData['income_value'] = incomeValue;
      }
      if (mobilePhone != null && mobilePhone.isNotEmpty) {
        bankData['mobile_phone'] = mobilePhone;
      }

      final response = await _dio.put('/workshop/$workshopId/banking', data: bankData);

      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro ao atualizar dados bancários'};
      }
    } on DioException catch (e) {
      final responseData = e.response?.data;
      String serverMessage = '';
      String? errorCode;
      String? field;
      if (responseData is Map) {
        serverMessage = (responseData['message'] ?? responseData['error'] ?? '').toString();
        errorCode = responseData['errorCode']?.toString();
        field = responseData['field']?.toString();
      } else if (responseData is String && responseData.isNotEmpty) {
        serverMessage = responseData;
      }
      final detail = serverMessage.isNotEmpty
          ? serverMessage
          : 'HTTP ${e.response?.statusCode ?? ''}: ${e.message ?? e.type.name}';
      return {
        'success': false,
        'error': detail,
        'errorCode': errorCode,
        'field': field,
        'statusCode': e.response?.statusCode,
      };
    } catch (e) {
      return {'success': false, 'error': 'Erro inesperado: ${e.toString()}'};
    }
  }

  // Método para obter dados bancários
  Future<Map<String, dynamic>> getBankDetails({required String workshopId}) async {
    try {
      await loadToken();
      
      final response = await _dio.get('/workshop/$workshopId/banking');
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': response.data};
      } else {
        return {'success': false, 'error': 'Erro ao obter dados bancários'};
      }
    } catch (e) {
      return {'success': false, 'error': 'Erro de conexão: ${e.toString()}'};
    }
  }
}















