/// Configurações do aplicativo MECA Oficina
class AppConfig {
  // ========================================
  // CONFIGURAÇÃO DA API - EC2 PRODUÇÃO
  // ========================================
  
  /// URL base da API (EC2 AWS)
  static const String apiBaseUrl = 'http://ec2-3-144-213-137.us-east-2.compute.amazonaws.com:9000';
  
  /// Usar endpoints admin para desenvolvimento
  static const bool useAdminEndpoints = true;
  
  /// Timeout de conexão (segundos) - Otimizado para EC2
  static const int connectionTimeout = 60;
  
  /// Timeout de recebimento (segundos) - Otimizado para EC2
  static const int receiveTimeout = 60;
  
  // ========================================
  // ONESIGNAL
  // ========================================
  
  /// OneSignal App ID
  static const String oneSignalAppId = 'tigcwsmthu7rujgcwrfkuyutg';
  
  // ========================================
  // TWILIO
  // ========================================
  // IMPORTANTE: Configurar no código ou via variáveis de ambiente
  // Para produção, usar flutter_dotenv ou similar
  
  /// Twilio Account SID (Produção)
  /// TODO: Mover para variáveis de ambiente
  static const String twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  
  /// Twilio Auth Token (Produção)
  /// TODO: Mover para variáveis de ambiente
  static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  
  /// Twilio Test Account SID
  static const String twilioTestAccountSid = 'YOUR_TWILIO_TEST_ACCOUNT_SID';
  
  /// Twilio Test Auth Token
  static const String twilioTestAuthToken = 'YOUR_TWILIO_TEST_AUTH_TOKEN';
  
  /// Usar credenciais de teste do Twilio
  static const bool useTwilioTestCredentials = false;
  
  // ========================================
  // APP INFO
  // ========================================
  
  /// Nome do app
  static const String appName = 'MECA Oficina';
  
  /// Versão do app
  static const String appVersion = '1.0.0';
  
  /// Build number
  static const String buildNumber = '1';
  
  // ========================================
  // GETTERS DINÂMICOS
  // ========================================
  
  /// Pega o Account SID correto do Twilio
  static String get twilioSid => useTwilioTestCredentials 
      ? twilioTestAccountSid 
      : twilioAccountSid;
  
  /// Pega o Auth Token correto do Twilio
  static String get twilioToken => useTwilioTestCredentials 
      ? twilioTestAuthToken 
      : twilioAuthToken;
  
  // ========================================
  // DEBUG
  // ========================================
  
  /// Imprime as configurações atuais
  static void printConfig() {
    print('========================================');
    print('MECA Oficina - Configurações');
    print('========================================');
    print('API Base URL: $apiBaseUrl');
    print('Use Admin Endpoints: $useAdminEndpoints');
    print('OneSignal App ID: $oneSignalAppId');
    print('Twilio Mode: ${useTwilioTestCredentials ? "TEST" : "PRODUCTION"}');
    print('App Version: $appVersion ($buildNumber)');
    print('========================================');
  }
}






  // ========================================
  // CONFIGURAÇÃO DA API - EC2 PRODUÇÃO
  // ========================================
  
  /// URL base da API (EC2 AWS)
  static const String apiBaseUrl = 'http://ec2-3-144-213-137.us-east-2.compute.amazonaws.com:9000';
  
  /// Usar endpoints admin para desenvolvimento
  static const bool useAdminEndpoints = true;
  
  /// Timeout de conexão (segundos) - Otimizado para EC2
  static const int connectionTimeout = 60;
  
  /// Timeout de recebimento (segundos) - Otimizado para EC2
  static const int receiveTimeout = 60;
  
  // ========================================
  // ONESIGNAL
  // ========================================
  
  /// OneSignal App ID
  static const String oneSignalAppId = 'tigcwsmthu7rujgcwrfkuyutg';
  
  // ========================================
  // TWILIO
  // ========================================
  // IMPORTANTE: Configurar no código ou via variáveis de ambiente
  // Para produção, usar flutter_dotenv ou similar
  
  /// Twilio Account SID (Produção)
  /// TODO: Mover para variáveis de ambiente
  static const String twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID';
  
  /// Twilio Auth Token (Produção)
  /// TODO: Mover para variáveis de ambiente
  static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN';
  
  /// Twilio Test Account SID
  static const String twilioTestAccountSid = 'YOUR_TWILIO_TEST_ACCOUNT_SID';
  
  /// Twilio Test Auth Token
  static const String twilioTestAuthToken = 'YOUR_TWILIO_TEST_AUTH_TOKEN';
  
  /// Usar credenciais de teste do Twilio
  static const bool useTwilioTestCredentials = false;
  
  // ========================================
  // APP INFO
  // ========================================
  
  /// Nome do app
  static const String appName = 'MECA Oficina';
  
  /// Versão do app
  static const String appVersion = '1.0.0';
  
  /// Build number
  static const String buildNumber = '1';
  
  // ========================================
  // GETTERS DINÂMICOS
  // ========================================
  
  /// Pega o Account SID correto do Twilio
  static String get twilioSid => useTwilioTestCredentials 
      ? twilioTestAccountSid 
      : twilioAccountSid;
  
  /// Pega o Auth Token correto do Twilio
  static String get twilioToken => useTwilioTestCredentials 
      ? twilioTestAuthToken 
      : twilioAuthToken;
  
  // ========================================
  // DEBUG
  // ========================================
  
  /// Imprime as configurações atuais
  static void printConfig() {
    print('========================================');
    print('MECA Oficina - Configurações');
    print('========================================');
    print('API Base URL: $apiBaseUrl');
    print('Use Admin Endpoints: $useAdminEndpoints');
    print('OneSignal App ID: $oneSignalAppId');
    print('Twilio Mode: ${useTwilioTestCredentials ? "TEST" : "PRODUCTION"}');
    print('App Version: $appVersion ($buildNumber)');
    print('========================================');
  }
}







