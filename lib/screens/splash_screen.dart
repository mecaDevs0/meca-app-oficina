import 'package:flutter/material.dart';

import '../services/storage_service.dart';
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
