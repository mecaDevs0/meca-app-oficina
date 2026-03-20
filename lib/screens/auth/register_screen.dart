import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../utils/form_styles.dart';
import '../../utils/cnpj_formatter.dart';
import '../../utils/cnpj_validator.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/email_formatter.dart';
import '../../utils/cep_formatter.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  
  // Controllers - Campos Mínimos
  final _nomeController = TextEditingController();
  final _cnpjController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cepController = TextEditingController();
  final _logradouroController = TextEditingController();
  final _numeroController = TextEditingController();
  final _bairroController = TextEditingController();
  final _cidadeController = TextEditingController();
  final _estadoController = TextEditingController();
  final _referralCodeController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSearchingCNPJ = false;
  bool _isSearchingCEP = false;
  String? _ownerName; // Nome do responsável obtido via QSA da ReceitaWS

  /// Limpa os campos preenchidos automaticamente
  void _limparCamposPreenchidos() {
    setState(() {
      _nomeController.clear();
      _emailController.clear();
      _phoneController.clear();
      _logradouroController.clear();
      _numeroController.clear();
      _bairroController.clear();
      _cidadeController.clear();
      _estadoController.clear();
      _cepController.clear();
      _ownerName = null;
    });
  }

  /// Busca dados do CNPJ na API (ReceitaWS - grátis)
  Future<void> _buscarDadosCNPJ(String cnpj) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cnpjLimpo.length != 14) return;

    setState(() => _isSearchingCNPJ = true);

    try {
      // API pública e gratuita da ReceitaWS
      final response = await http.get(
        Uri.parse('https://www.receitaws.com.br/v1/cnpj/$cnpjLimpo'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] != 'ERROR' && data['nome'] != null) {
          // Extrair nome do responsável via QSA (quadro de sócios e administradores)
          String? ownerNameFromQsa;
          final qsa = data['qsa'];
          if (qsa != null && qsa is List && qsa.isNotEmpty) {
            ownerNameFromQsa = qsa[0]['nome'] as String?;
          }

          setState(() {
            _nomeController.text = data['nome'] ?? '';
            _emailController.text = data['email'] ?? '';
            _phoneController.text = data['telefone']?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

            // Endereço
            _logradouroController.text = data['logradouro'] ?? '';
            _numeroController.text = data['numero'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['municipio'] ?? '';
            _estadoController.text = data['uf'] ?? '';
            _cepController.text = data['cep']?.replaceAll(RegExp(r'[^\d]'), '') ?? '';

            // Responsável pelo CNPJ
            _ownerName = ownerNameFromQsa;
          });

          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dados preenchidos automaticamente! Você pode editar qualquer campo.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          // CNPJ inválido ou não encontrado
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚠️ CNPJ não encontrado ou inválido. Preencha os dados manualmente.'),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Erro na API
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Erro ao buscar CNPJ. Tente novamente ou preencha manualmente.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      // Erro de conexão ou timeout
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ Erro de conexão ao buscar CNPJ. Verifique sua internet e tente novamente.'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }

    setState(() => _isSearchingCNPJ = false);
  }

  /// Busca CEP na API dos Correios (ViaCEP - grátis)
  Future<void> _buscarCEP(String cep) async {
    final cepLimpo = cep.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cepLimpo.length != 8) return;

    setState(() => _isSearchingCEP = true);

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['erro'] == null) {
          setState(() {
            _logradouroController.text = data['logradouro'] ?? '';
            _bairroController.text = data['bairro'] ?? '';
            _cidadeController.text = data['localidade'] ?? '';
            _estadoController.text = data['uf'] ?? '';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Endereço preenchido automaticamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
    }

    setState(() => _isSearchingCEP = false);
  }

  Future<void> _handleRegister() async {
    // Validar formulário primeiro - isso vai marcar campos inválidos em vermelho
    if (!_formKey.currentState!.validate()) {
      // Se a validação falhou, os campos já foram marcados como inválidos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Por favor, preencha todos os campos obrigatórios corretamente'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    // Validação adicional do CNPJ antes de enviar
    final cnpjLimpo = _cnpjController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (cnpjLimpo.length != 14) {
      _formKey.currentState!.validate(); // Re-validar para marcar o campo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CNPJ deve ter 14 dígitos'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      setState(() {}); // Atualizar UI para mostrar campo inválido
      return;
    }
    
    // Validar dígitos verificadores do CNPJ
    if (!CnpjValidator.isValid(_cnpjController.text)) {
      _formKey.currentState!.validate(); // Re-validar para marcar o campo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('CNPJ inválido. Verifique os dígitos verificadores.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {}); // Atualizar UI para mostrar campo inválido
      return;
    }

    // Verificar se todos os campos obrigatórios estão preenchidos
    final camposVazios = <String>[];
    if (_nomeController.text.trim().isEmpty) camposVazios.add('Nome da Oficina');
    if (_emailController.text.trim().isEmpty) camposVazios.add('Email');
    if (_passwordController.text.isEmpty) camposVazios.add('Senha');
    if (_phoneController.text.replaceAll(RegExp(r'[^\d]'), '').length < 10) camposVazios.add('Telefone');
    if (_cepController.text.replaceAll(RegExp(r'[^\d]'), '').length != 8) camposVazios.add('CEP');
    if (_logradouroController.text.trim().isEmpty) camposVazios.add('Rua');
    if (_numeroController.text.trim().isEmpty) camposVazios.add('Número');
    if (_bairroController.text.trim().isEmpty) camposVazios.add('Bairro');
    if (_cidadeController.text.trim().isEmpty) camposVazios.add('Cidade');
    if (_estadoController.text.trim().length != 2) camposVazios.add('UF');

    if (camposVazios.isNotEmpty) {
      _formKey.currentState!.validate(); // Re-validar para marcar campos
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Campos obrigatórios não preenchidos: ${camposVazios.join(', ')}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );
      setState(() {}); // Atualizar UI
      return;
    }

    setState(() => _isLoading = true);

    final data = {
      'name': _nomeController.text.trim(),
      'owner_name': _ownerName ?? '',
      'cnpj': _cnpjController.text, // Será normalizado no api_service
      'email': _emailController.text.trim(),
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'address': {
        'cep': _cepController.text,
        'logradouro': _logradouroController.text.trim(),
        'numero': _numeroController.text.trim(),
        'bairro': _bairroController.text.trim(),
        'cidade': _cidadeController.text.trim(),
        'estado': _estadoController.text.trim().toUpperCase(),
      },
      'horario_funcionamento': {
        'segunda': '08:00-18:00',
        'terca': '08:00-18:00',
        'quarta': '08:00-18:00',
        'quinta': '08:00-18:00',
        'sexta': '08:00-18:00',
      }
    };
    final referralCode = _referralCodeController.text.trim();
    if (referralCode.isNotEmpty) {
      data['referral_code'] = referralCode;
    }

    // Log dos dados que serão enviados (sem senha) para debug
    final address = data['address'] as Map<String, dynamic>? ?? {};
    print('📤 [Register] Enviando dados de cadastro:');
    print('  - Nome: ${data['name']}');
    print('  - CNPJ: ${data['cnpj']}');
    print('  - Email: ${data['email']}');
    print('  - Telefone: ${data['phone']}');
    print('  - CEP: ${address['cep']}');
    print('  - Endereço: ${address['logradouro']}, ${address['numero']}');
    print('  - Bairro: ${address['bairro']}');
    print('  - Cidade: ${address['cidade']}');
    print('  - Estado: ${address['estado']}');
    if (referralCode.isNotEmpty) {
      print('  - Código de indicação: $referralCode');
    }

    final result = await _apiService.registerWorkshop(data);

    setState(() => _isLoading = false);
    
    // Log do resultado
    print('📥 [Register] Resultado: ${result['success'] ? '✅ Sucesso' : '❌ Erro'}');
    if (!result['success']) {
      print('  - Erro: ${result['error']}');
    }

    if (result['success']) {
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withOpacity(0.7),
        builder: (context) => Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF00C977),
                  Color(0xFF00A86B),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Ícone de sucesso com animação
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    color: Colors.white,
                    size: 60,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Título
                const Text(
                  'Cadastro Enviado!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Mensagem principal
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Sua oficina foi cadastrada com sucesso!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1A1A1A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              const Color(0xFF00C977).withOpacity(0.1),
                              const Color(0xFF00A86B).withOpacity(0.1),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF00C977).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00C977).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.info_outline,
                                color: Color(0xFF00C977),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Expanded(
                              child: Text(
                                'Aguarde a aprovação do administrador. Você receberá um email em breve.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Color(0xFF1A1A1A),
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Botão
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00C977),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.3),
                    ),
                    child: const Text(
                      'Ir para Login',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['error'] ?? 'Erro ao cadastrar oficina'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
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
                            'Cadastro de Oficina',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : textColor,
                            ),
                          ),
                          Text(
                            'Preencha os dados abaixo',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white.withOpacity(0.7) : textColor.withOpacity(0.7),
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
                    padding: const EdgeInsets.all(25),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // CNPJ (com busca automática)
                          _buildSectionTitle('🏢 Dados da Empresa'),
                          const SizedBox(height: 15),
                          
                          TextFormField(
                            controller: _cnpjController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'CNPJ *',
                              hint: '00.000.000/0000-00',
                              prefixIcon: const Icon(Icons.badge, color: AppColors.primaryColor),
                              suffixIcon: _isSearchingCNPJ
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : const Icon(Icons.search, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CnpjFormatter(),
                              LengthLimitingTextInputFormatter(18),
                            ],
                            validator: (value) {
                              // Usar validador completo de CNPJ
                              return CnpjValidator.validate(value);
                            },
                            onChanged: (value) {
                              final cnpjLimpo = value.replaceAll(RegExp(r'[^\d]'), '');
                              
                              // Se o CNPJ foi reduzido (números removidos), limpar campos
                              if (cnpjLimpo.length < 14) {
                                _limparCamposPreenchidos();
                              }
                              
                              // Se o CNPJ está completo (14 dígitos), buscar dados
                              if (cnpjLimpo.length == 14) {
                                _buscarDadosCNPJ(value);
                              }
                            },
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _nomeController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Nome da Oficina *',
                              prefixIcon: const Icon(Icons.business, color: AppColors.primaryColor),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _phoneController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Telefone/WhatsApp *',
                              hint: '(00) 00000-0000',
                              prefixIcon: const Icon(Icons.phone, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              PhoneInputFormatter(),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              if (value!.replaceAll(RegExp(r'[^\d]'), '').length < 10) {
                                return 'Telefone inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _emailController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Email *',
                              prefixIcon: const Icon(Icons.email, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.emailAddress,
                            inputFormatters: [EmailFormatter()],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              if (!value!.contains('@')) return 'Email inválido';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 30),
                          _buildSectionTitle('📍 Endereço'),
                          const SizedBox(height: 15),

                          // CEP (com busca automática)
                          TextFormField(
                            controller: _cepController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'CEP *',
                              hint: '00000-000',
                              prefixIcon: const Icon(Icons.location_on, color: AppColors.primaryColor),
                              suffixIcon: _isSearchingCEP
                                  ? const Padding(
                                      padding: EdgeInsets.all(12),
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      ),
                                    )
                                  : const Icon(Icons.search, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              CepFormatter(),
                              LengthLimitingTextInputFormatter(9),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              final cepLimpo = value!.replaceAll(RegExp(r'[^\d]'), '');
                              if (cepLimpo.length != 8) return 'CEP deve ter 8 dígitos';
                              return null;
                            },
                            onChanged: (value) {
                              if (value.length == 8) {
                                _buscarCEP(value);
                              }
                            },
                          ),
                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _logradouroController,
                                  style: FormStyles.inputTextStyle(context),
                                  cursorColor: AppColors.primaryColor,
                                  decoration: _inputDecoration(
                                    context,
                                    label: 'Rua *',
                                    prefixIcon: const Icon(Icons.home, color: AppColors.primaryColor),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _numeroController,
                                  style: FormStyles.inputTextStyle(context),
                                  cursorColor: AppColors.primaryColor,
                                  decoration: _inputDecoration(
                                    context,
                                    label: 'Nº *',
                                  ),
                                  keyboardType: TextInputType.number,
                                  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _bairroController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Bairro *',
                              prefixIcon: const Icon(Icons.map, color: AppColors.primaryColor),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 15),

                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: _cidadeController,
                                  style: FormStyles.inputTextStyle(context),
                                  cursorColor: AppColors.primaryColor,
                                  decoration: _inputDecoration(
                                    context,
                                    label: 'Cidade *',
                                    prefixIcon: const Icon(Icons.location_city, color: AppColors.primaryColor),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _estadoController,
                                  style: FormStyles.inputTextStyle(context),
                                  cursorColor: AppColors.primaryColor,
                                  decoration: _inputDecoration(
                                    context,
                                    label: 'UF *',
                                    hint: 'SP',
                                  ),
                                  textCapitalization: TextCapitalization.characters,
                                  maxLength: 2,
                                  validator: (value) {
                                    if (value?.isEmpty ?? true) return 'Obrigatório';
                                    if (value!.length != 2) return 'Inválido';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 30),
                          _buildSectionTitle('🎁 Indicação (opcional)'),
                          const SizedBox(height: 15),
                          TextFormField(
                            controller: _referralCodeController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Código de Indicação',
                              hint: 'Ex: MEC-1001',
                              prefixIcon: const Icon(Icons.card_giftcard_outlined, color: AppColors.primaryColor),
                            ),
                            textCapitalization: TextCapitalization.characters,
                          ),
                          const SizedBox(height: 30),
                          _buildSectionTitle('🔐 Segurança'),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Senha *',
                              hint: 'Mínimo 6 caracteres',
                              prefixIcon: const Icon(Icons.lock, color: AppColors.primaryColor),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: Colors.grey[600],
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              if (value!.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          
                          const SizedBox(height: 30),

                          // Botão de Cadastro
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleRegister,
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
                                      'Cadastrar Oficina',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Link para Login
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Já tem uma conta? ',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              TextButton(
                                onPressed: () {
                                  Navigator.pop(context);
                                },
                                child: const Text(
                                  'Fazer Login',
                                  style: TextStyle(
                                    color: AppColors.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          
                          // Info sobre autopreenchimento
                          Container(
                            padding: const EdgeInsets.all(15),
                            decoration: BoxDecoration(
                              color: Colors.green[50],
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(color: Colors.green[200]!),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.lightbulb_outline, color: Colors.green, size: 20),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Dica: Digite seu CNPJ ou CEP completo para preencher automaticamente!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.green[800],
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
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return FormStyles.decorate(
      context,
      InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        fillColor: isDark ? const Color(0xFF2A2A2A) : AppColors.primaryBlueColor.withOpacity(0.05),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final textColor = ThemeService.getTextColor(isDark);
    
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
    );
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _cnpjController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _cepController.dispose();
    _logradouroController.dispose();
    _numeroController.dispose();
    _bairroController.dispose();
    _cidadeController.dispose();
    _estadoController.dispose();
    super.dispose();
  }
}