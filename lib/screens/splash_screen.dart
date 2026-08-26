import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../services/storage_service.dart';
import '../services/onesignal_service.dart';
import '../services/api_service.dart';
import '../widgets/animation_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));

    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    _fadeController.forward();
    
    await Future.delayed(const Duration(milliseconds: 3000));
    
    final token = await StorageService.getToken();
    
    if (token != null) {
      final apiService = ApiService();
      // Registrar workshopId no OneSignal para receber push via external_user_id
      try {
        await apiService.loadToken();
        final workshopId = await apiService.getWorkshopId();
        if (workshopId != null && workshopId.isNotEmpty) {
          await OneSignalService.setExternalUserId(workshopId);
          if (kDebugMode) {
            debugPrint('[Splash] OneSignal.login($workshopId) chamado com sucesso');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Splash] Erro ao registrar workshopId no OneSignal: $e');
        }
      }
      try {
        final playerId = OneSignalService.getSubscriptionId();
        if (playerId != null) {
          await apiService.saveDeviceToken(playerId);
          if (kDebugMode) {
            debugPrint('[Splash] Device token salvo após verificar token existente');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Splash] Erro ao salvar device token: $e');
        }
      }
    }
    
    if (mounted) {
      if (token != null) {
        Navigator.pushReplacementNamed(context, '/core');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1F2937),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: AnimationWidgets.buildEnterAnimation(width: 500, height: 500),
        ),
      ),
    );
  }
}
