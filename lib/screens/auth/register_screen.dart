import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/theme_switch_widget.dart';
import '../../core/app_colors.dart';

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
  
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isSearchingCNPJ = false;
  bool _isSearchingCEP = false;

  /// Busca dados do CNPJ na API (ReceitaWS - grátis)
  Future<void> _buscarDadosCNPJ(String cnpj) async {
    final cnpjLimpo = cnpj.replaceAll(RegExp(r'[^\d]'), '');
    
    if (cnpjLimpo.length != 14) return;

    setState(() => _isSearchingCNPJ = true);

    try {
      // API pública e gratuita da ReceitaWS
      final response = await http.get(
        Uri.parse('https://www.receitaws.com.br/v1/cnpj/$cnpjLimpo'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['status'] != 'ERROR') {
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
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Dados preenchidos automaticamente!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Erro ao buscar CNPJ: $e');
      // Não mostrar erro ao usuário, apenas não preenche
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
      print('Erro ao buscar CEP: $e');
    }

    setState(() => _isSearchingCEP = false);
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final data = {
      'name': _nomeController.text,
      'cnpj': _cnpjController.text,
      'email': _emailController.text,
      'password': _passwordController.text,
      'phone': _phoneController.text,
      'address': {
        'cep': _cepController.text,
        'logradouro': _logradouroController.text,
        'numero': _numeroController.text,
        'bairro': _bairroController.text,
        'cidade': _cidadeController.text,
        'estado': _estadoController.text,
      },
      'horario_funcionamento': {
        'segunda': '08:00-18:00',
        'terca': '08:00-18:00',
        'quarta': '08:00-18:00',
        'quinta': '08:00-18:00',
        'sexta': '08:00-18:00',
      }
    };

    final result = await _apiService.registerWorkshop(data);

    setState(() => _isLoading = false);

    if (result['success']) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.check_circle, color: Colors.green, size: 30),
              ),
              const SizedBox(width: 15),
              const Expanded(
                child: Text(
                  'Cadastro Enviado!',
                  style: TextStyle(fontSize: 20),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sua oficina foi cadastrada com sucesso!',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: Colors.blue),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Aguarde a aprovação do administrador. Você receberá um email em breve.',
                        style: TextStyle(fontSize: 14, color: Colors.blue),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Ir para Login',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
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
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    
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
                            'Cadastro de Oficina',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : textColor,
                            ),
                          ),
                          Text(
                            'Preencha os dados abaixo',
                            style: TextStyle(
                              fontSize: 14,
                              color: isDark ? Colors.white.withOpacity(0.7) : textColor.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const ThemeSwitchButton(),
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
                            decoration: InputDecoration(
                              labelText: 'CNPJ *',
                              hintText: '00.000.000/0000-00',
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
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(14),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              if (value!.replaceAll(RegExp(r'[^\d]'), '').length != 14) {
                                return 'CNPJ deve ter 14 dígitos';
                              }
                              return null;
                            },
                            onChanged: (value) {
                              if (value.length == 14) {
                                _buscarDadosCNPJ(value);
                              }
                            },
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _nomeController,
                            decoration: const InputDecoration(
                              labelText: 'Nome da Oficina *',
                              prefixIcon: Icon(Icons.business, color: AppColors.primaryColor),
                            ),
                            validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
                          ),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Telefone/WhatsApp *',
                              hintText: '(00) 00000-0000',
                              prefixIcon: Icon(Icons.phone, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.phone,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(11),
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
                            decoration: const InputDecoration(
                              labelText: 'Email *',
                              prefixIcon: Icon(Icons.email, color: AppColors.primaryColor),
                            ),
                            keyboardType: TextInputType.emailAddress,
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
                            decoration: InputDecoration(
                              labelText: 'CEP *',
                              hintText: '00000-000',
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
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(8),
                            ],
                            validator: (value) {
                              if (value?.isEmpty ?? true) return 'Campo obrigatório';
                              if (value!.length != 8) return 'CEP inválido';
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
                                  decoration: const InputDecoration(
                                    labelText: 'Rua *',
                                    prefixIcon: Icon(Icons.home, color: AppColors.primaryColor),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _numeroController,
                                  decoration: const InputDecoration(
                                    labelText: 'Nº *',
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
                            decoration: const InputDecoration(
                              labelText: 'Bairro *',
                              prefixIcon: Icon(Icons.map, color: AppColors.primaryColor),
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
                                  decoration: const InputDecoration(
                                    labelText: 'Cidade *',
                                    prefixIcon: Icon(Icons.location_city, color: AppColors.primaryColor),
                                  ),
                                  validator: (value) => value?.isEmpty ?? true ? 'Obrigatório' : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: TextFormField(
                                  controller: _estadoController,
                                  decoration: const InputDecoration(
                                    labelText: 'UF *',
                                    hintText: 'SP',
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
                          _buildSectionTitle('🔐 Segurança'),
                          const SizedBox(height: 15),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Senha *',
                              hintText: 'Mínimo 6 caracteres',
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
