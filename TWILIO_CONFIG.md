# 🔐 Configuração do Twilio

## ⚠️ IMPORTANTE: Credenciais Sensíveis

As credenciais do Twilio **NÃO** devem ser commitadas no GitHub por questões de segurança.

## 📝 Como Configurar

### **Credenciais de Produção:**
```dart
// Em lib/config/app_config.dart, substitua:
static const String twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID_HERE';
static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN_HERE';
```

### **Credenciais de Teste:**
```dart
static const String twilioTestAccountSid = 'YOUR_TEST_ACCOUNT_SID_HERE';
static const String twilioTestAuthToken = 'YOUR_TEST_AUTH_TOKEN_HERE';
```

**📧 As credenciais reais foram enviadas por email/documento separado por segurança.**

## 🔄 Para Alternar Entre Teste e Produção

```dart
// Em lib/config/app_config.dart:
static const bool useTwilioTestCredentials = false; // Produção
static const bool useTwilioTestCredentials = true;  // Teste
```

## ✅ Onde Configurar

**Arquivo:** `lib/config/app_config.dart`

**Linhas:** 34-44

## 🚀 Próximos Passos Recomendados

Para produção, considere usar:
1. **flutter_dotenv** - Para variáveis de ambiente
2. **AWS Secrets Manager** - Para secrets na nuvem
3. **Environment Variables** - No CI/CD

## 📱 Número Twilio

Não esqueça de configurar seu número Twilio em:
```dart
// lib/services/twilio_service.dart linha 13
static const String _twilioPhoneNumber = '+SEU_NUMERO_TWILIO';
```

---

**⚠️ NUNCA commite credenciais reais no Git!**




## ⚠️ IMPORTANTE: Credenciais Sensíveis

As credenciais do Twilio **NÃO** devem ser commitadas no GitHub por questões de segurança.

## 📝 Como Configurar

### **Credenciais de Produção:**
```dart
// Em lib/config/app_config.dart, substitua:
static const String twilioAccountSid = 'YOUR_TWILIO_ACCOUNT_SID_HERE';
static const String twilioAuthToken = 'YOUR_TWILIO_AUTH_TOKEN_HERE';
```

### **Credenciais de Teste:**
```dart
static const String twilioTestAccountSid = 'YOUR_TEST_ACCOUNT_SID_HERE';
static const String twilioTestAuthToken = 'YOUR_TEST_AUTH_TOKEN_HERE';
```

**📧 As credenciais reais foram enviadas por email/documento separado por segurança.**

## 🔄 Para Alternar Entre Teste e Produção

```dart
// Em lib/config/app_config.dart:
static const bool useTwilioTestCredentials = false; // Produção
static const bool useTwilioTestCredentials = true;  // Teste
```

## ✅ Onde Configurar

**Arquivo:** `lib/config/app_config.dart`

**Linhas:** 34-44

## 🚀 Próximos Passos Recomendados

Para produção, considere usar:
1. **flutter_dotenv** - Para variáveis de ambiente
2. **AWS Secrets Manager** - Para secrets na nuvem
3. **Environment Variables** - No CI/CD

## 📱 Número Twilio

Não esqueça de configurar seu número Twilio em:
```dart
// lib/services/twilio_service.dart linha 13
static const String _twilioPhoneNumber = '+SEU_NUMERO_TWILIO';
```

---

**⚠️ NUNCA commite credenciais reais no Git!**















