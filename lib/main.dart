import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/auth/forgot_password_screen.dart';
import 'screens/core/core_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/schedule/schedule_screen.dart';
import 'screens/financial/financial_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/config/agenda_config_screen.dart';
import 'screens/config/bank_account_screen.dart';
import 'screens/config/services_config_screen.dart';
import 'screens/config/pagbank_config_screen.dart';
import 'screens/config/installment_config_screen.dart';
import 'screens/service/service_details_screen.dart';
import 'screens/bookings/booking_detail_screen.dart';
import 'screens/insights/insights_screen.dart';
import 'screens/notifications/notifications_screen.dart';
import 'services/theme_service.dart';
void main() {
  runApp(const MecaOficinaApp());
}

class MecaOficinaApp extends StatelessWidget {
  const MecaOficinaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => ThemeService(),
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
            return MaterialPageRoute(builder: (_) => const SplashScreen());
          case '/login':
            return MaterialPageRoute(builder: (_) => const LoginScreen());
          case '/register':
            return MaterialPageRoute(builder: (_) => const RegisterScreen());
          case '/forgot-password':
            return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
          case '/core':
            return MaterialPageRoute(builder: (_) => const CoreScreen());
          case '/home':
            return MaterialPageRoute(builder: (_) => const HomeScreen());
          case '/schedule':
            return MaterialPageRoute(builder: (_) => const ScheduleScreen());
          case '/financial':
            return MaterialPageRoute(builder: (_) => const FinancialScreen());
          case '/profile':
            return MaterialPageRoute(builder: (_) => const ProfileScreen());
          case '/config/agenda':
            return MaterialPageRoute(builder: (_) => const AgendaConfigScreen());
          case '/config/bank':
            return MaterialPageRoute(builder: (_) => const BankAccountScreen());
          case '/config/services':
            return MaterialPageRoute(builder: (_) => const ServicesConfigScreen());
          case '/config/installment':
            return MaterialPageRoute(builder: (_) => const InstallmentConfigScreen());
          case '/service/details':
            return MaterialPageRoute(
              builder: (_) => ServiceDetailsScreen(
                serviceId: settings.arguments as String? ?? '',
              ),
            );
          case '/booking-detail':
            final args = settings.arguments as Map<String, dynamic>;
            return MaterialPageRoute(
              builder: (_) => BookingDetailScreen(booking: args),
            );
                 case '/insights':
                   return MaterialPageRoute(builder: (_) => const InsightsScreen());
                 case '/notifications':
                   return MaterialPageRoute(builder: (_) => const NotificationsScreen());
                 case '/config/pagbank':
                   return MaterialPageRoute(builder: (_) => const PagBankConfigScreen());
                 default:
                   return MaterialPageRoute(builder: (_) => const SplashScreen());
        }
      },
          );
        },
      ),
    );
  }
}