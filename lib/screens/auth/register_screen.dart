import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/appsflyer_service.dart';
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
          // Extrair nome do responsável via QSA
          String? ownerNameFromQsa;
          final qsa = data['qsa'];
          if (qsa != null && qsa is List && qsa.isNotEmpty) {
            ownerNameFromQsa = qsa[0]['nome'] as String?;
          }

          setState(() => _isSearchingCNPJ = false);

          if (!mounted) return;

          // Mostrar bottom sheet de revisão dos dados do CNPJ
          final result = await _showCnpjReviewSheet(
            nome: data['nome'] ?? '',
            email: data['email'] ?? '',
            telefone: data['telefone']?.replaceAll(RegExp(r'[^\d]'), '') ?? '',
            logradouro: data['logradouro'] ?? '',
            numero: data['numero'] ?? '',
            bairro: data['bairro'] ?? '',
            cidade: data['municipio'] ?? '',
            estado: data['uf'] ?? '',
            cep: data['cep']?.replaceAll(RegExp(r'[^\d]'), '') ?? '',
            ownerName: ownerNameFromQsa ?? '',
          );

          // Agendar atualização para o próximo frame — garante que o
          // bottom sheet está 100% disposed antes de tocar nos controllers
          if (result != null && mounted) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!mounted) return;
              _nomeController.text = result['nome'] ?? '';
              _emailController.text = result['email'] ?? '';
              _phoneController.text = result['telefone'] ?? '';
              _logradouroController.text = result['logradouro'] ?? '';
              _numeroController.text = result['numero'] ?? '';
              _bairroController.text = result['bairro'] ?? '';
              _cidadeController.text = result['cidade'] ?? '';
              _estadoController.text = result['estado'] ?? '';
              _cepController.text = result['cep'] ?? '';
              setState(() {
                _ownerName = (result['ownerName'] ?? '').isNotEmpty ? result['ownerName'] : null;
              });
            });
          }

          return; // Skip the setState(_isSearchingCNPJ = false) below since sheet handles it
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

  /// Mostra bottom sheet de revisão dos dados do CNPJ.
  /// Retorna Map<String, String> com os dados confirmados, ou null se cancelou.
  Future<Map<String, String>?> _showCnpjReviewSheet({
    required String nome,
    required String email,
    required String telefone,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required String cep,
    required String ownerName,
  }) {
    final userTypedName = _nomeController.text.trim();
    return showModalBottomSheet<Map<String, String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CnpjReviewSheetContent(
        razaoSocial: nome,
        initialNome: userTypedName,
        email: email,
        telefone: telefone,
        logradouro: logradouro,
        numero: numero,
        bairro: bairro,
        cidade: cidade,
        estado: estado,
        cep: cep,
        ownerName: ownerName,
      ),
    );
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
    final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^\d]'), '');
    if (phoneDigits.length != 11 || phoneDigits[2] != '9') camposVazios.add('Celular');
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
      final workshopId = result['data']?['id']?.toString() ?? '';
      AppsFlyerService.instance.logRegistration('email', workshopId);
      AppsFlyerService.instance.applyDeferredDeepLink();

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
                              hint: 'Ex: Oficina do João, Auto Center Silva...',
                              prefixIcon: const Icon(Icons.business, color: AppColors.primaryColor),
                              suffixIcon: Tooltip(
                                message: 'Visível para clientes',
                                child: Icon(Icons.visibility, color: AppColors.primaryColor.withOpacity(0.7), size: 20),
                              ),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 4),
                          Padding(
                            padding: const EdgeInsets.only(left: 12),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 14, color: AppColors.primaryColor.withOpacity(0.7)),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'Este nome será exibido para os clientes no app',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.primaryColor.withOpacity(0.8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _phoneController,
                            style: FormStyles.inputTextStyle(context),
                            cursorColor: AppColors.primaryColor,
                            decoration: _inputDecoration(
                              context,
                              label: 'Celular/WhatsApp *',
                              hint: '(11) 98765-4321',
                              prefixIcon: const Icon(Icons.phone, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              PhoneInputFormatter(),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              final digits = value!.replaceAll(RegExp(r'[^\d]'), '');
                              if (digits.length != 11 || digits[2] != '9') {
                                return 'Informe um celular válido (DDD + 9 + 8 dígitos). Linhas fixas não são aceitas.';
                              }
                              return null;
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 4, left: 4),
                            child: Text(
                              'Apenas celular (não fixo). Ex: (11) 98765-4321. Necessário para ativar recebimentos.',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
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

/// Widget isolado para o bottom sheet de revisão CNPJ.
/// Gerencia seus próprios controllers — evita _dependents.isEmpty.
class _CnpjReviewSheetContent extends StatefulWidget {
  final String razaoSocial;
  final String initialNome;
  final String email;
  final String telefone;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;
  final String cep;
  final String ownerName;

  const _CnpjReviewSheetContent({
    required this.razaoSocial,
    required this.initialNome,
    required this.email,
    required this.telefone,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
    required this.cep,
    required this.ownerName,
  });

  @override
  State<_CnpjReviewSheetContent> createState() => _CnpjReviewSheetContentState();
}

class _CnpjReviewSheetContentState extends State<_CnpjReviewSheetContent> {
  late final TextEditingController _nome;
  late final TextEditingController _email;
  late final TextEditingController _telefone;
  late final TextEditingController _logradouro;
  late final TextEditingController _numero;
  late final TextEditingController _bairro;
  late final TextEditingController _cidade;
  late final TextEditingController _estado;
  late final TextEditingController _cep;
  late final TextEditingController _ownerName;

  @override
  void initState() {
    super.initState();
    _nome = TextEditingController(text: widget.initialNome.isNotEmpty ? widget.initialNome : '');
    _email = TextEditingController(text: widget.email);
    _telefone = TextEditingController(text: _formatPhone(widget.telefone));
    _logradouro = TextEditingController(text: widget.logradouro);
    _numero = TextEditingController(text: widget.numero);
    _bairro = TextEditingController(text: widget.bairro);
    _cidade = TextEditingController(text: widget.cidade);
    _estado = TextEditingController(text: widget.estado);
    _cep = TextEditingController(text: _formatCep(widget.cep));
    _ownerName = TextEditingController(text: widget.ownerName);
  }

  @override
  void dispose() {
    _nome.dispose();
    _email.dispose();
    _telefone.dispose();
    _logradouro.dispose();
    _numero.dispose();
    _bairro.dispose();
    _cidade.dispose();
    _estado.dispose();
    _cep.dispose();
    _ownerName.dispose();
    super.dispose();
  }

  static String _formatPhone(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
    }
    if (digits.length == 10) {
      return '(${digits.substring(0, 2)}) ${digits.substring(2, 6)}-${digits.substring(6)}';
    }
    return raw;
  }

  static String _formatCep(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 8) {
      return '${digits.substring(0, 5)}-${digits.substring(5)}';
    }
    return raw;
  }

  void _confirm() {
    final data = <String, String>{
      'nome': _nome.text.isNotEmpty ? _nome.text : widget.razaoSocial,
      'email': _email.text,
      'telefone': _telefone.text.replaceAll(RegExp(r'\D'), ''),
      'logradouro': _logradouro.text,
      'numero': _numero.text,
      'bairro': _bairro.text,
      'cidade': _cidade.text,
      'estado': _estado.text,
      'cep': _cep.text.replaceAll(RegExp(r'\D'), ''),
      'ownerName': _ownerName.text,
    };
    Navigator.of(context).pop(data);
  }

  Widget _field(String label, TextEditingController controller, bool isDark, {String? hint, TextInputType? keyboardType, List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.grey[500], fontSize: 13),
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[600], fontStyle: FontStyle.italic, fontSize: 13),
          filled: true,
          fillColor: isDark ? const Color(0xFF252525) : Colors.grey[50],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF00C977), width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[600],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.business_outlined, color: Color(0xFF00C977), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dados encontrados',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Confira e ajuste se necessário',
                        style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.grey[600], fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (widget.razaoSocial.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : Colors.grey[50],
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.apartment, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.razaoSocial,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500], fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),
          // Scrollable fields
          Flexible(
            child: Padding(
              padding: EdgeInsets.only(bottom: bottomInset),
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _field('Nome da oficina', _nome, isDark, hint: widget.razaoSocial),
                    _field('Responsavel', _ownerName, isDark),
                    _field('Email', _email, isDark),
                    _field('Telefone', _telefone, isDark, keyboardType: TextInputType.phone, inputFormatters: [PhoneInputFormatter(), LengthLimitingTextInputFormatter(15)]),
                    _field('Logradouro', _logradouro, isDark),
                    Row(
                      children: [
                        Expanded(flex: 2, child: _field('Numero', _numero, isDark)),
                        const SizedBox(width: 10),
                        Expanded(flex: 3, child: _field('Bairro', _bairro, isDark)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(flex: 3, child: _field('Cidade', _cidade, isDark)),
                        const SizedBox(width: 10),
                        Expanded(flex: 1, child: _field('UF', _estado, isDark)),
                      ],
                    ),
                    _field('CEP', _cep, isDark, keyboardType: TextInputType.number, inputFormatters: [CepFormatter(), LengthLimitingTextInputFormatter(9)]),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
          ),
          // Action buttons
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00C977),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      onPressed: _confirm,
                      icon: const Icon(Icons.check_circle_outline, size: 18),
                      label: const Text(
                        'Confirmar dados',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark ? const Color(0xFF222A27) : const Color(0xFFF2FBF7),
                        foregroundColor: isDark ? Colors.white : const Color(0xFF0E7A4F),
                        side: BorderSide(
                          color: isDark ? const Color(0xFF305C49) : const Color(0xFFCBEFDD),
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: () => Navigator.of(context).pop(null),
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: isDark ? Colors.white70 : const Color(0xFF0E7A4F),
                      ),
                      label: Text(
                        'Preencher manualmente',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF0E7A4F),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
