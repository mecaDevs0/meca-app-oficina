/// Configurações do aplicativo MECA Oficina
class AppConfig {
  // ========================================
  // CONFIGURAÇÃO DA API - EC2 PRODUÇÃO
  // ========================================
  
  /// URL base da API (EC2 AWS)
  static const String apiBaseUrl = 'http://ec2-3-144-213-137.us-east-2.compute.amazonaws.com:9000';
  
  /// Timeout de conexão (segundos) - Otimizado para EC2
  static const int connectionTimeout = 60;
  
  /// Timeout de recebimento (segundos) - Otimizado para EC2
  static const int receiveTimeout = 60;
  
  /// Usar endpoints admin (sempre false - usar endpoints reais)
  static const bool useAdminEndpoints = false;
  
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
  // PAGSEGURO / PAGBANK
  // ========================================
  
  /// Chave pública PagBank
  static const String pagBankPublicKey = 'YOUR_PUBLIC_KEY_HERE'; // TODO: Adicionar chave real
  
  /// Taxa da plataforma MECA (5%)
  static const double mecaPlatformFee = 0.05; // 5%
  
  // ========================================
  // GOOGLE MAPS
  // ========================================
  
  /// Google Maps API Key (Android)
  static const String googleMapsApiKeyAndroid = 'YOUR_ANDROID_KEY_HERE'; // TODO: Adicionar chave real
  
  /// Google Maps API Key (iOS)
  static const String googleMapsApiKeyIos = 'YOUR_IOS_KEY_HERE'; // TODO: Adicionar chave real
  
  // ========================================
  // FIREBASE / NOTIFICAÇÕES
  // ========================================
  
  /// Firebase Project ID
  static const String firebaseProjectId = 'meca-oficina';
  
  // ========================================
  // TWILIO / SMS
  // ========================================
  
  /// Twilio Account SID
  static const String twilioSid = 'YOUR_TWILIO_SID_HERE';
  
  /// Twilio Auth Token
  static const String twilioToken = 'YOUR_TWILIO_TOKEN_HERE';
  
  // ========================================
  // ONESIGNAL / PUSH NOTIFICATIONS
  // ========================================
  
  /// OneSignal App ID
  static const String oneSignalAppId = 'YOUR_ONESIGNAL_APP_ID_HERE';
  
  // ========================================
  // DEBUG
  // ========================================
  
  /// Imprime as configurações atuais
  static void printConfig() {
    print('========================================');
    print('MECA Oficina - Configurações');
    print('========================================');
    print('API Base URL: $apiBaseUrl');
    print('App Version: $appVersion ($buildNumber)');
    print('MECA Platform Fee: ${mecaPlatformFee * 100}%');
    print('========================================');
  }
}






