import 'dart:convert';

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

  bool _isTokenExpired(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return true;

      String payload = parts[1];
      switch (payload.length % 4) {
        case 2: payload += '=='; break;
        case 3: payload += '='; break;
      }

      final decoded = utf8.decode(base64Url.decode(payload));
      final Map<String, dynamic> payloadMap = json.decode(decoded);

      final exp = payloadMap['exp'];
      if (exp == null) return false;

      final expSeconds = exp is int ? exp : int.tryParse(exp.toString());
      if (expSeconds == null) return false;

      return DateTime.now().millisecondsSinceEpoch > expSeconds * 1000;
    } catch (e) {
      return true;
    }
  }

  Future<void> _startSplashSequence() async {
    _fadeController.forward();

    await Future.delayed(const Duration(milliseconds: 3000));

    final token = await StorageService.getToken();

    if (token != null && token.isNotEmpty && !_isTokenExpired(token)) {
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
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/core');
      }
    } else {
      if (token != null) {
        await StorageService.clearToken();
        if (kDebugMode) {
          debugPrint('[Splash] Token expirado — redirecionando para login');
        }
      }
      if (mounted) {
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
