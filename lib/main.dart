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
import 'screens/config/bank_account_screen.dart';
import 'screens/config/installment_config_screen.dart';
import 'screens/config/pagbank_config_screen.dart';
import 'screens/config/services_config_screen.dart';
import 'screens/core/core_screen.dart';
import 'screens/financial/financial_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/service/service_details_screen.dart';
import 'screens/splash_screen.dart';
import 'services/theme_service.dart';
import 'utils/page_transitions.dart';

void main() {
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

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeService()),
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => ServicesProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
                 return MaterialApp(
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
          case '/profile':
            return PageTransitions.fade(const ProfileScreen());
          case '/config/agenda':
            return PageTransitions.slideFromRight(const AgendaConfigScreen());
          case '/config/bank':
            return PageTransitions.slideFromRight(const BankAccountScreen());
          case '/config/services':
            return PageTransitions.slideFromRight(ServicesConfigScreen());
          case '/config/installment':
            return PageTransitions.slideFromRight(const InstallmentConfigScreen());
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
          case '/config/pagbank':
            return PageTransitions.slideFromRight(const PagBankConfigScreen());
          default:
            return PageTransitions.fade(const SplashScreen());
        }
      },
          );
        },
      ),
    );
  }
}