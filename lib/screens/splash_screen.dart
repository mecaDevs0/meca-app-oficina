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
    
    // Se usuário já está logado, salvar device token
    if (token != null) {
      try {
        final playerId = OneSignalService.getSubscriptionId();
        if (playerId != null) {
          final apiService = ApiService();
          await apiService.saveDeviceToken(playerId);
          if (kDebugMode) {
            print('[Splash] Device token salvo após verificar token existente');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('[Splash] Erro ao salvar device token: $e');
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
