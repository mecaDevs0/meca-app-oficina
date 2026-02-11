/// Configurações do aplicativo MECA Oficina
class AppConfig {
  // ========================================
  // CONFIGURAÇÃO DA API - EC2 PRODUÇÃO
  // ========================================
  
  /// URL base da API (Produção - HTTPS via NGINX)
  static const String apiBaseUrl = 'https://api.mecabr.com';
  
  /// Timeout de conexão (segundos) - Otimizado para EC2
  static const int connectionTimeout = 60;
  
  /// Timeout de recebimento (segundos) - Otimizado para EC2
  static const int receiveTimeout = 60;
  
  /// Timeout para carregamento da home (notificações, perfil, PagBank, agenda, etc.)
  static const int homeLoadTimeoutSeconds = 30;
  
  /// Usar endpoints admin (sempre false - usar endpoints reais)
  static const bool useAdminEndpoints = false;
  
  // ========================================
  // APP INFO
  // ========================================
  
  /// Nome do app
  static const String appName = 'MECA Oficina';
  
  /// Versão do app
  static const String appVersion = '1.7.1';
  
  /// Build number
  static const String buildNumber = '116';
  
  // ========================================
  // PAGSEGURO / PAGBANK
  // ========================================
  
  /// Chave pública PagBank
  static const String pagBankPublicKey = 'YOUR_PUBLIC_KEY_HERE'; // TODO: Adicionar chave real
  
  /// Taxa da plataforma MECA (12%). A MECA arca com 100% das taxas PagBank; a oficina não é descontada.
  static const double mecaPlatformFee = 0.12; // 12%
  
  // ========================================
  // GOOGLE MAPS
  // ========================================
  
  /// Google Maps API Key (Android)
  static const String googleMapsApiKeyAndroid = 'YOUR_ANDROID_KEY_HERE'; // TODO: Adicionar chave real
  
  /// Google Maps API Key (iOS)
  static const String googleMapsApiKeyIos = 'YOUR_IOS_KEY_HERE'; // TODO: Adicionar chave real

  // ========================================
  // LOGIN SOCIAL
  // ========================================

  /// OAuth Client ID do Google para Android (meca oficina)
  static const String googleClientIdAndroid =
      '767232279794-jkfqe8qa17m2lg7hcgp0qepn801olbns.apps.googleusercontent.com';

  /// OAuth Client ID do Google para iOS (meca oficina)
  static const String googleClientIdIos =
      '767232279794-n1gj11jqlaj6j49kjchdl3l43jioskil.apps.googleusercontent.com';

  /// OAuth Client ID do Google usado como serverClientId (web)
  static const String googleClientIdWeb =
      '767232279794-tn09hsoednrtm3vonkfep0ec1qrob6v1.apps.googleusercontent.com';

  /// Service ID configurado no Apple Developer
  static const String appleServiceId = 'com.meca.app.service';
  
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
  static const String oneSignalAppId = 'b2d9eb72-de92-4a59-ab91-30484d64f403';
  
  // ========================================
  // DEBUG
  // ========================================
  
  /// Imprime as configurações atuais
  static void printConfig() {
  }
}






