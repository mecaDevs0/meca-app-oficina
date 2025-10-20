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
    
    // Configurar animação de fade
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

    // Iniciar animação e navegação
    _startSplashSequence();
  }

  Future<void> _startSplashSequence() async {
    // Iniciar animação de fade
    _fadeController.forward();
    
    // Aguardar a animação de entrada
    await Future.delayed(const Duration(milliseconds: 3000));
    
    // Verificar se o usuário já está logado
    final token = await StorageService.getToken();
    
    if (mounted) {
      if (token != null) {
        // Usuário já logado, ir para home
        Navigator.pushReplacementNamed(context, '/core');
      } else {
        // Usuário não logado, ir para login
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animação de entrada
              AnimationWidgets.buildEnterAnimation(width: 250, height: 250),
              
              const SizedBox(height: 40),
              
              // Título MECA
              const Text(
                'MECA',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 6,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Subtítulo
              const Text(
                'Oficina',
                style: TextStyle(
                  fontSize: 18,
                  color: Color(0xFF00C977),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                ),
              ),
              
              const SizedBox(height: 60),
              
              // Indicador de loading
              const SizedBox(
                width: 30,
                height: 30,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}