import 'dart:io';
import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:permission_handler/permission_handler.dart';

import '../config/app_config.dart';

// Callback para quando uma notificação push é recebida
typedef OnNotificationReceived = void Function(OSNotification notification);

class OneSignalService {
  static String get _appId => AppConfig.oneSignalAppId;
  static OnNotificationReceived? _onNotificationReceived;
  static GlobalKey<NavigatorState>? _navigatorKey;

  /// Define a chave do Navigator para permitir navegação a partir de notificações push
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _navigatorKey = key;
  }

  static void setNotificationReceivedCallback(OnNotificationReceived? callback) {
    _onNotificationReceived = callback;
  }
  
  static Future<void> initialize() async {
    if (_appId == 'YOUR_ONESIGNAL_APP_ID_HERE' || _appId.isEmpty) {
      print('[OneSignal] App ID não configurado. Push notifications não funcionarão.');
      return;
    }
    
    try {
      // Configurar log level baseado na plataforma
      if (Platform.isIOS) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      } else {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      }
      
      // Inicializar OneSignal
      OneSignal.initialize(_appId);
      
      // No iOS, garantir que o OneSignal está pronto antes de continuar
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 300));
      }
      
      // Solicitar permissão runtime para Android 13+ (POST_NOTIFICATIONS)
      if (Platform.isAndroid) {
        try {
          final notificationPermission = await Permission.notification.status;
          if (notificationPermission.isDenied) {
            print('[OneSignal] Solicitando permissão POST_NOTIFICATIONS (Android 13+)...');
            final result = await Permission.notification.request();
            print('[OneSignal] Resultado da permissão POST_NOTIFICATIONS: $result');
          } else {
            print('[OneSignal] Permissão POST_NOTIFICATIONS já concedida: $notificationPermission');
          }
        } catch (e) {
          print('[OneSignal] Erro ao solicitar permissão POST_NOTIFICATIONS: $e');
        }
      }
      
      // Solicitar permissão de notificações via OneSignal
      // Para iOS, é importante solicitar permissão explicitamente
      final permissionGranted = await OneSignal.Notifications.requestPermission(true);
      print('[OneSignal] Permissão de notificações OneSignal: $permissionGranted');
      
      // Aguardar um pouco para garantir que a subscription está pronta (especialmente no iOS)
      if (Platform.isIOS) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
      
      // Verificar status da subscription
      final subscriptionId = OneSignal.User.pushSubscription.id;
      final isSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
      print('[OneSignal] Subscription ID: ${subscriptionId ?? "null"}');
      print('[OneSignal] Is Subscribed: $isSubscribed');
      
      // No iOS, verificar se o token está disponível
      if (Platform.isIOS) {
        final token = OneSignal.User.pushSubscription.token;
        print('[OneSignal] Push Token: ${token ?? "null"}');
        
        // Se não está inscrito, tentar novamente após um delay
        if (!isSubscribed && subscriptionId == null) {
          print('[OneSignal] iOS: Subscription não disponível, tentando novamente...');
          await Future.delayed(const Duration(seconds: 1));
          final retrySubscriptionId = OneSignal.User.pushSubscription.id;
          final retryIsSubscribed = OneSignal.User.pushSubscription.optedIn ?? false;
          print('[OneSignal] Retry - Subscription ID: ${retrySubscriptionId ?? "null"}');
          print('[OneSignal] Retry - Is Subscribed: $retryIsSubscribed');
        }
      }
      
      _setupHandlers();
      print('[OneSignal] Inicializado com sucesso. App ID: ${_appId.substring(0, 8)}...');
    } catch (e) {
      print('[OneSignal] Erro ao inicializar: $e');
    }
  }
  
  static void _setupHandlers() {
    // Handler para quando a notificação é clicada (background ou foreground)
    OneSignal.Notifications.addClickListener((event) {
      print('[OneSignal] Notificação clicada');
      print('[OneSignal] Notification ID: ${event.notification.notificationId}');
      print('[OneSignal] Title: ${event.notification.title}');
      print('[OneSignal] Body: ${event.notification.body}');
      _handleNotificationOpened(event);
    });
    
    // Handler para quando a notificação chega com o app em foreground
    // IMPORTANTE: Sempre chamar display() para garantir que a notificação apareça
    OneSignal.Notifications.addForegroundWillDisplayListener((event) {
      print('[OneSignal] Notificação recebida em foreground - exibindo...');
      print('[OneSignal] Notification ID: ${event.notification.notificationId}');
      print('[OneSignal] Title: ${event.notification.title}');
      print('[OneSignal] Body: ${event.notification.body}');
      // Sempre exibir a notificação, mesmo em foreground
      event.notification.display();
      
      // Chamar callback para atualizar notificações
      if (_onNotificationReceived != null) {
        _onNotificationReceived!(event.notification);
      }
    });
    
    // Handler para mudanças de permissão
    OneSignal.Notifications.addPermissionObserver((state) {
      print('[OneSignal] Permissão mudou: $state');
    });
    
    // Listener para mudanças no status de subscription
    OneSignal.User.pushSubscription.addObserver((state) {
      final subscription = OneSignal.User.pushSubscription;
      print('[OneSignal] Subscription mudou: ID=${subscription.id}, OptedIn=${subscription.optedIn}');
    });
  }
  
  static void _handleNotificationOpened(OSNotificationClickEvent event) {
    final notification = event.notification;
    final additionalData = notification.additionalData;

    if (additionalData != null) {
      final action = additionalData['action']?.toString();

      // Navegar para tela de dados bancários quando oficina recebe push de pagamento falhado
      if (action == 'open_bank_account_screen') {
        print('[OneSignal] Ação: abrir tela de dados bancários');
        _navigateTo('/config/banking');
      } else if (additionalData.containsKey('booking_id')) {
        final bookingId = additionalData['booking_id'].toString();
        print('[OneSignal] Notificação clicada - booking_id: $bookingId');
        _navigateTo('/booking-detail', arguments: {'id': bookingId});
      } else if (additionalData.containsKey('type')) {
        final type = additionalData['type'].toString();
        print('[OneSignal] Notificação clicada - type: $type');
      }
    }

    // Chamar callback para atualizar notificações quando clicada
    if (_onNotificationReceived != null) {
      _onNotificationReceived!(notification);
    }
  }

  /// Navega para uma rota usando o navigatorKey global
  static void _navigateTo(String route, {Object? arguments}) {
    final navigator = _navigatorKey?.currentState;
    if (navigator != null) {
      navigator.pushNamed(route, arguments: arguments);
    } else {
      print('[OneSignal] Navigator key não disponível para navegar para $route');
    }
  }
  
  static Future<void> setExternalUserId(String userId) async {
    await OneSignal.login(userId);
  }
  
  static Future<void> removeExternalUserId() async {
    await OneSignal.logout();
  }
  
  static String? getSubscriptionId() {
    return OneSignal.User.pushSubscription.id;
  }
  
  static String? getSubscriptionToken() {
    return OneSignal.User.pushSubscription.token;
  }
  
  static bool isSubscribed() {
    return OneSignal.User.pushSubscription.optedIn ?? false;
  }
}












