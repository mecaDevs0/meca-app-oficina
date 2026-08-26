import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/appsflyer_service.dart';
import '../../services/onesignal_service.dart';
import '../../widgets/animation_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final result = await _apiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );

      if (!mounted) return;
      if (result['success']) {
      // Registrar workshopId no OneSignal para receber push via external_user_id
      try {
        final workshopId = await _apiService.getWorkshopId();
        if (workshopId != null && workshopId.isNotEmpty) {
          await OneSignalService.setExternalUserId(workshopId);
          debugPrint('[Login] OneSignal.login($workshopId) chamado com sucesso');
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Login] Erro ao registrar workshopId no OneSignal: $e');
        }
      }
      // Salvar device token após login bem-sucedido
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        String? playerId;
        for (int i = 0; i < 3; i++) {
          playerId = OneSignalService.getSubscriptionId();
          if (playerId != null && playerId.isNotEmpty) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }

        if (playerId != null && playerId.isNotEmpty) {
          await _apiService.saveDeviceToken(playerId);
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint('[Login] Erro ao salvar device token após login: $e');
        }
      }
      // AppsFlyer: log login + set CUID
      try {
        final wId = await _apiService.getWorkshopId();
        if (wId != null && wId.isNotEmpty) {
          AppsFlyerService.instance.setCustomerUserId(wId);
          AppsFlyerService.instance.logLogin(wId);
        }
      } catch (_) {}

        AppsFlyerService.instance.applyDeferredDeepLink();
        await _onLoginSuccess();
      } else {
        _showError(result['error'] ?? 'Erro ao fazer login');
      }
    } on Exception catch (e) {
      if (!mounted) return;
      final msg = e.toString().toLowerCase();
      if (msg.contains('timeout') || msg.contains('timed out')) {
        _showError('Tempo esgotado. Verifique sua conexão e tente novamente.');
      } else if (msg.contains('connection') || msg.contains('socket') || msg.contains('network')) {
        _showError('Sem conexão. Verifique a internet e tente novamente.');
      } else {
        _showError('Não foi possível conectar. Tente novamente.');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erro ao fazer login. Tente novamente.');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;
    final isSmallScreen = screenHeight < 700;
    final formBottomPadding = mediaQuery.padding.bottom > 0
        ? mediaQuery.padding.bottom + 18
        : 24.0;
    
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF252940), Color(0xFF1B1D2E)],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Logo Section - Hero Area com mais presença
              Padding(
                padding: EdgeInsets.fromLTRB(
                  32,
                  isSmallScreen ? 18 : 28,
                  32,
                  isSmallScreen ? 18 : 26,
                ),
                child: Column(
                  children: [
                    SizedBox(
                      width: isSmallScreen ? 112 : 132,
                      height: isSmallScreen ? 112 : 132,
                      child: Image.asset(
                        'assets/logos/icone_verde.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 10 : 14),
                    Text(
                      'MECA',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 28 : 34,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 5,
                      ),
                    ),
                    SizedBox(height: isSmallScreen ? 6 : 8),
                    Text(
                      'Oficina Parceira',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 12 : 13,
                        color: Colors.white70,
                        letterSpacing: 1.6,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              // Form Section - painel branco ancorado ao rodapé
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, -6),
                      ),
                    ],
                  ),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final verticalPadding = isSmallScreen ? 24.0 : 30.0;

                      return SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(
                          28,
                          verticalPadding,
                          28,
                          formBottomPadding,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: constraints.maxHeight - verticalPadding - formBottomPadding,
                          ),
                          child: IntrinsicHeight(
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  SizedBox(height: isSmallScreen ? 4 : 8),
                                  const Text(
                                    'Bem-vindo!',
                                    style: TextStyle(
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF252940),
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Faça login para gerenciar sua oficina com agilidade e acompanhar seus atendimentos.',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                      height: 1.45,
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 28 : 36),

                                  TextFormField(
                                    controller: _emailController,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    cursorColor: AppColors.primaryColor,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: _authDecoration(
                                      label: 'Email',
                                      prefixIcon: Icons.email_outlined,
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Campo obrigatório';
                                      if (!value!.contains('@')) return 'Email inválido';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 16,
                                      height: 1.5,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    cursorColor: AppColors.primaryColor,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _handleLogin(),
                                    decoration: _authDecoration(
                                      label: 'Senha',
                                      prefixIcon: Icons.lock_outline,
                                      suffixIcon: IconButton(
                                        icon: Icon(
                                          _obscurePassword
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                          color: Colors.grey[600],
                                          size: 20,
                                        ),
                                        onPressed: () {
                                          setState(() => _obscurePassword = !_obscurePassword);
                                        },
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                    ),
                                    validator: (value) {
                                      if (value?.isEmpty ?? true) return 'Campo obrigatório';
                                      if (value!.length < 6) return 'Mínimo 6 caracteres';
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: TextButton(
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/forgot-password');
                                      },
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Esqueceu a senha?',
                                        style: TextStyle(
                                          color: AppColors.primaryColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: isSmallScreen ? 28 : 36),

                                  SizedBox(
                                    width: double.infinity,
                                    height: 56,
                                    child: ElevatedButton(
                                      onPressed: _isLoading ? null : _handleLogin,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primaryColor,
                                        foregroundColor: Colors.white,
                                        disabledBackgroundColor: AppColors.primaryColor.withOpacity(0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(18),
                                        ),
                                        elevation: 0,
                                        shadowColor: Colors.transparent,
                                      ),
                                      child: _isLoading
                                          ? SizedBox(
                                              width: 24,
                                              height: 24,
                                              child: AnimationWidgets.buildLoadingAnimation(
                                                width: 24,
                                                height: 24,
                                              ),
                                            )
                                          : const Text(
                                              'Entrar',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 0.5,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const Spacer(),
                                  SizedBox(height: isSmallScreen ? 20 : 28),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF7FAFC),
                                      borderRadius: BorderRadius.circular(22),
                                      border: Border.all(
                                        color: const Color(0xFFE3E8EF),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Não tem uma conta? ',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                            fontSize: 14,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            Navigator.pushNamed(context, '/register');
                                          },
                                          style: TextButton.styleFrom(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 4,
                                              vertical: 4,
                                            ),
                                            minimumSize: Size.zero,
                                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                          ),
                                          child: const Text(
                                            'Cadastre-se',
                                            style: TextStyle(
                                              color: AppColors.primaryColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  InputDecoration _authDecoration({
    required String label,
    IconData? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: Color(0xFF4B5563),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.primaryColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      hintText: label == 'Email' ? 'oficina@exemplo.com' : 'Digite sua senha',
      hintStyle: TextStyle(
        color: Colors.grey[400],
        fontSize: 16,
      ),
      prefixIcon: prefixIcon != null
          ? Padding(
              padding: const EdgeInsets.only(left: 16, right: 12),
              child: Icon(
                prefixIcon,
                color: AppColors.primaryColor,
                size: 22,
              ),
            )
          : null,
      prefixIconConstraints: const BoxConstraints(
        minWidth: 48,
        minHeight: 24,
      ),
      suffixIcon: suffixIcon,
      suffixIconConstraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 24,
      ),
      filled: true,
      fillColor: AppColors.primaryBlueColor.withOpacity(0.05),
      contentPadding: const EdgeInsets.symmetric(
        vertical: 20,
        horizontal: 16,
      ),
      isDense: false,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(
          color: Colors.grey.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: AppColors.primaryColor,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 2,
        ),
      ),
      constraints: const BoxConstraints(
        minHeight: 56,
      ),
    );
  }

  Future<void> _onLoginSuccess() async {
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/core');
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}
