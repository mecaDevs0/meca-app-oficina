import 'dart:convert';

import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}








import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}










import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}








import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}














import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}








import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}










import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}








import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class TwilioService {
  // Credenciais Twilio (configuradas no AppConfig)
  static String get _accountSid => AppConfig.twilioSid;
  static String get _authToken => AppConfig.twilioToken;
  static const String _baseUrl = 'https://api.twilio.com/2010-04-01';
  
  // Número do Twilio (você precisa configurar um número no Twilio)
  static const String _twilioPhoneNumber = '+1234567890'; // Substitua pelo seu número Twilio
  
  /// Enviar SMS
  static Future<Map<String, dynamic>> sendSMS({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Messages.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Body': message,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('SMS sent successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'SMS enviado com sucesso',
          'data': data,
        };
      } else {
        print('Failed to send SMS: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao enviar SMS: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error sending SMS: $e');
      return {
        'success': false,
        'error': 'Erro ao enviar SMS: $e',
      };
    }
  }
  
  /// Enviar SMS de notificação de novo agendamento
  static Future<Map<String, dynamic>> sendBookingNotification({
    required String customerPhone,
    required String customerName,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
Olá! 👋

Novo agendamento recebido:
Cliente: $customerName
Serviço: $serviceName
Data: $date
Horário: $time

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de confirmação de agendamento
  static Future<Map<String, dynamic>> sendBookingConfirmation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
✅ Agendamento Confirmado!

Serviço: $serviceName
Data: $date
Horário: $time

Obrigado por escolher nossa oficina!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de lembrete de agendamento
  static Future<Map<String, dynamic>> sendBookingReminder({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
  }) async {
    final message = '''
🔔 Lembrete de Agendamento

Olá! Lembramos que você tem um agendamento:

Serviço: $serviceName
Data: $date
Horário: $time

Nos vemos em breve!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de cancelamento de agendamento
  static Future<Map<String, dynamic>> sendBookingCancellation({
    required String customerPhone,
    required String serviceName,
    required String date,
    required String time,
    String? reason,
  }) async {
    final message = '''
❌ Agendamento Cancelado

Seu agendamento foi cancelado:

Serviço: $serviceName
Data: $date
Horário: $time
${reason != null ? '\nMotivo: $reason' : ''}

Para reagendar, entre em contato conosco.

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Enviar SMS de conclusão de serviço
  static Future<Map<String, dynamic>> sendServiceCompletion({
    required String customerPhone,
    required String serviceName,
    required double totalAmount,
  }) async {
    final message = '''
✅ Serviço Concluído!

Serviço: $serviceName
Valor: R\$ ${totalAmount.toStringAsFixed(2)}

Obrigado pela confiança!

MECA - Sua oficina digital
''';
    
    return await sendSMS(to: customerPhone, message: message);
  }
  
  /// Fazer uma chamada de voz (para casos importantes)
  static Future<Map<String, dynamic>> makeCall({
    required String to,
    required String message,
  }) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/Calls.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      // TwiML para a mensagem de voz
      final twiml = '''<?xml version="1.0" encoding="UTF-8"?>
<Response>
    <Say language="pt-BR">$message</Say>
</Response>''';
      
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'From': _twilioPhoneNumber,
          'To': to,
          'Twiml': twiml,
        },
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('Call initiated successfully: ${data['sid']}');
        return {
          'success': true,
          'message': 'Chamada iniciada com sucesso',
          'data': data,
        };
      } else {
        print('Failed to initiate call: ${response.statusCode} - ${response.body}');
        return {
          'success': false,
          'error': 'Falha ao iniciar chamada: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error initiating call: $e');
      return {
        'success': false,
        'error': 'Erro ao iniciar chamada: $e',
      };
    }
  }
  
  /// Verificar número de telefone
  static Future<Map<String, dynamic>> verifyPhoneNumber(String phoneNumber) async {
    try {
      final url = Uri.parse('$_baseUrl/Accounts/$_accountSid/IncomingPhoneNumbers.json');
      
      final credentials = base64Encode(utf8.encode('$_accountSid:$_authToken'));
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Basic $credentials',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'error': 'Falha ao verificar número: ${response.statusCode}',
        };
      }
    } catch (e) {
      print('Error verifying phone number: $e');
      return {
        'success': false,
        'error': 'Erro ao verificar número: $e',
      };
    }
  }
}














