import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/theme_service.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../utils/form_styles.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;
  bool _emailSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSendEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _apiService.forgotPassword(_emailController.text);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() => _emailSent = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Código de acesso enviado por email!'),
          backgroundColor: AppColors.primaryColor,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erro ao enviar email'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF252940), const Color(0xFF1B1D2E)]
                : [const Color(0xFFF5F7FA), const Color(0xFFE5E7EB)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : textColor),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recuperar Senha',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : textColor,
                            ),
                          ),
                          Text(
                            'Enviaremos um email para você',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white70 : textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                    boxShadow: [
                      BoxShadow(
                        color: isDark 
                            ? Colors.black.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(30),
                    child: _emailSent ? _buildSuccessView() : _buildFormView(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormView() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.lock_reset,
            size: 80,
            color: AppColors.primaryColor,
          ),
          const SizedBox(height: 30),
          
          Text(
            'Esqueceu sua senha?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF252940),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            'Digite seu email cadastrado e enviaremos um código para redefinir sua senha.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 30),

          TextFormField(
            controller: _emailController,
            style: TextStyle(
              color: isDark ? Colors.white : const Color(0xFF1F2937),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: AppColors.primaryColor,
            decoration: FormStyles.decorate(
              context,
              InputDecoration(
              labelText: 'Email',
              labelStyle: TextStyle(color: isDark ? Colors.white70 : Colors.grey[600]),
              hintText: 'seu@email.com',
              hintStyle: TextStyle(color: isDark ? Colors.white54 : Colors.grey[400]),
              prefixIcon: const Icon(Icons.email, color: AppColors.primaryColor),
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.primaryBlueColor.withOpacity(0.05),
              ),
            ),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value?.isEmpty ?? true) return 'Campo obrigatório';
              if (!value!.contains('@')) return 'Email inválido';
              return null;
            },
          ),
          const SizedBox(height: 30),

          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleSendEmail,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                elevation: 5,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Enviar Email',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Icon(
          Icons.mark_email_read,
          size: 100,
          color: AppColors.primaryColor,
        ),
        const SizedBox(height: 30),

        Text(
          'Email Enviado!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(height: 15),

        Text(
          'Enviamos um código para:\n${_emailController.text}',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: textColor.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 20),

        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.primaryColor.withOpacity(isDark ? 0.15 : 0.08),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: AppColors.primaryColor.withOpacity(0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Como acessar sua conta:',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildStep('1', 'Abra o email e copie o código recebido', textColor),
              const SizedBox(height: 8),
              _buildStep('2', 'Use o código como senha no login', textColor),
              const SizedBox(height: 8),
              _buildStep('3', 'Após entrar, vá em Configurações e crie uma nova senha', textColor),
            ],
          ),
        ),
        const SizedBox(height: 30),

        OutlinedButton(
          onPressed: () {
            Navigator.pop(context);
          },
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          child: const Text(
            'Voltar para Login',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(String number, String text, Color textColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primaryColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: textColor.withOpacity(0.85),
            ),
          ),
        ),
      ],
    );
  }

}

