import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'providers/notification_provider.dart';
import 'providers/services_provider.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/bookings/booking_detail_screen.dart';
import 'screens/config/agenda_config_screen.dart';
import 'screens/config/banking_screen.dart';
import 'screens/config/installment_config_screen.dart';
import 'screens/config/fiscal_config_screen.dart';
import 'screens/config/services_config_screen.dart';
import 'screens/core/core_screen.dart';
import 'screens/financial/anticipation_screen.dart';
import 'screens/financial/financial_screen.dart';
import 'screens/financial/financial_history_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/referral_screen.dart';
import 'screens/pre_compra/pre_compra_detail_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/service/service_details_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/workshop/image_management_screen.dart';
import 'services/theme_service.dart';
import 'services/onesignal_service.dart';
import 'services/api_service.dart';
import 'utils/page_transitions.dart';

void main() async {
  // Wrapper para capturar erros não tratados
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    if (kDebugMode) {
      print('Flutter Error: ${details.exception}');
      print('Stack: ${details.stack}');
    }
  };
  
  try {
    WidgetsFlutterBinding.ensureInitialized();
  } catch (e) {
    if (kDebugMode) {
      print('Erro ao inicializar Flutter binding: $e');
    }
  }
  
  // Inicializar OneSignal de forma assíncrona
  Future.microtask(() async {
    try {
      await OneSignalService.initialize();
      
      // Aguardar um pouco para garantir que o token está disponível
      // Tentar salvar o token periodicamente até conseguir
      Future.delayed(const Duration(seconds: 2), () async {
        for (int attempt = 0; attempt < 5; attempt++) {
          try {
            final playerId = OneSignalService.getSubscriptionId();
            if (playerId != null && playerId.isNotEmpty) {
              print('[Main] Token OneSignal encontrado: ${playerId.substring(0, 20)}...');
              // Salvar token no backend se usuário estiver logado
              final apiService = ApiService();
              final prefs = await apiService.getStorage();
              final token = prefs.getString('token');
              if (token != null) {
                final result = await apiService.saveDeviceToken(playerId);
                if (result['success'] == true) {
                  print('[Main] Device token salvo com sucesso no backend');
                  break; // Sucesso, parar tentativas
                } else {
                  print('[Main] Erro ao salvar device token: ${result['error']}');
                }
              } else {
                print('[Main] Usuário não está logado, token não será salvo');
                break; // Usuário não logado, não precisa continuar
              }
            } else {
              print('[Main] Tentativa ${attempt + 1}/5: Token OneSignal ainda não disponível');
            }
          } catch (e) {
            if (kDebugMode) {
              print('[Main] Erro ao salvar device token (tentativa ${attempt + 1}): $e');
            }
          }
          
          // Aguardar antes da próxima tentativa
          if (attempt < 4) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar OneSignal: $e');
      }
    }
  });
  
  try {
    runApp(const MecaOficinaApp());
  } catch (e, stackTrace) {
    if (kDebugMode) {
      print('Erro crítico ao iniciar app: $e');
      print('Stack trace: $stackTrace');
    }
    // Tentar rodar app básico em caso de erro
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('Erro ao inicializar app. Por favor, reinstale o aplicativo.'),
          ),
        ),
      ),
    );
  }
}

class MecaOficinaApp extends StatelessWidget {
  const MecaOficinaApp({Key? key}) : super(key: key);

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    // Registrar navigatorKey para navegação a partir de push notifications
    OneSignalService.setNavigatorKey(navigatorKey);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ServicesProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: _NotificationListenerWrapper(
        child: Consumer<ThemeService>(
          builder: (context, themeService, child) {
                   return MaterialApp(
                   navigatorKey: navigatorKey,
                   title: 'MECA Oficina',
                   debugShowCheckedModeBanner: false,
                   theme: ThemeService.lightTheme,
                   darkTheme: ThemeService.darkTheme,
                   themeMode: themeService.themeMode,
      initialRoute: '/',
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return PageTransitions.fade(const SplashScreen());
          case '/login':
            return PageTransitions.slideFromRight(const LoginScreen());
          case '/register':
            return PageTransitions.slideFromRight(const RegisterScreen());
          case '/forgot-password':
            return PageTransitions.slideFromRight(const ForgotPasswordScreen());
          case '/core':
            return PageTransitions.fade(const CoreScreen());
          case '/home':
            return PageTransitions.fade(const HomeScreen());
          case '/schedule':
            return PageTransitions.fade(const ScheduleScreen());
          case '/financial':
            return PageTransitions.fade(const FinancialScreen());
          case '/financial-history':
            return PageTransitions.slideFromRight(const FinancialHistoryScreen());
          case '/financial/anticipation':
            return PageTransitions.slideFromRight(const AnticipationScreen());
          case '/profile':
            return PageTransitions.fade(const ProfileScreen());
          case '/referrals':
            return PageTransitions.slideFromRight(const ReferralScreen());
          case '/config/agenda':
            return PageTransitions.slideFromRight(const AgendaConfigScreen());
          case '/config/bank':
            // Rota legada — redireciona para a tela unificada BankingScreen
            return PageTransitions.slideFromRight(const BankingScreen());
          case '/config/services':
            return PageTransitions.slideFromRight(ServicesConfigScreen());
          case '/config/installment':
            return PageTransitions.slideFromRight(const InstallmentConfigScreen());
          case '/config/fiscal':
            return PageTransitions.slideFromRight(const FiscalConfigScreen());
          case '/service/details':
            return PageTransitions.slideFromRight(
              ServiceDetailsScreen(
                serviceId: settings.arguments as String? ?? '',
              ),
            );
          case '/booking-detail':
            final args = settings.arguments as Map<String, dynamic>;
            return PageTransitions.slideFromRight(
              BookingDetailScreen(booking: args),
            );
          case '/insights':
            return PageTransitions.slideFromRight(const InsightsScreen());
          case '/notifications':
            return PageTransitions.slideFromRight(const NotificationsScreen());
          case '/config/banking':
            return PageTransitions.slideFromRight(const BankingScreen());
          case '/portfolio':
            return PageTransitions.slideFromRight(const ImageManagementScreen());
          case '/pre-compra-detail':
            final args = settings.arguments as Map<String, dynamic>?;
            return PageTransitions.slideFromRight(
              PreCompraDetailOfinaScreen(preCompraId: args?['id']?.toString() ?? ''),
            );
          default:
            return PageTransitions.fade(const SplashScreen());
        }
      },
          );
          },
        ),
      ),
    );
  }
}

// Widget wrapper para configurar o listener de notificações push
class _NotificationListenerWrapper extends StatefulWidget {
  final Widget child;

  const _NotificationListenerWrapper({required this.child});

  @override
  State<_NotificationListenerWrapper> createState() => _NotificationListenerWrapperState();
}

class _NotificationListenerWrapperState extends State<_NotificationListenerWrapper> {
  @override
  void initState() {
    super.initState();
    // Configurar callback para atualizar notificações quando chegam push
    OneSignalService.setNotificationReceivedCallback((notification) {
      print('[NotificationListener] Push notification recebida: ${notification.notificationId}');
      // Atualizar contador de notificações não lidas
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          final provider = Provider.of<NotificationProvider>(context, listen: false);
          // Incrementar contador de não lidas
          final currentCount = provider.unreadNotifications;
          provider.setUnreadNotifications(currentCount + 1, resetBadge: false);
          print('[NotificationListener] Contador atualizado: ${currentCount + 1}');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}