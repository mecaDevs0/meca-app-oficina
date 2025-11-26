import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class PagBankAccountScreen extends StatefulWidget {
  const PagBankAccountScreen({Key? key}) : super(key: key);

  @override
  State<PagBankAccountScreen> createState() => _PagBankAccountScreenState();
}

class _PagBankAccountScreenState extends State<PagBankAccountScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  final ApiService _apiService = ApiService();

  // Form controllers - APENAS campos necessários para criar conta PagBank SELLER
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(); // Nome/Razão Social (obrigatório)
  final _businessNameController = TextEditingController(); // Nome fantasia (opcional)
  final _emailController = TextEditingController(); // Email (obrigatório)
  final _taxIdController = TextEditingController(); // CPF ou CNPJ (obrigatório)
  final _phoneController = TextEditingController(); // Telefone (obrigatório)
  final _birthDateController = TextEditingController(); // Data de nascimento (opcional)
  final _personNameController = TextEditingController(); // Nome da pessoa física (obrigatório para person)
  final _personEmailController = TextEditingController(); // Email da pessoa física (obrigatório para person)
  final _personCpfController = TextEditingController(); // CPF da pessoa física (obrigatório para person)
  final _motherNameController = TextEditingController(); // Nome da mãe (obrigatório para person)
  final _cepController = TextEditingController(); // CEP (obrigatório)
  final _streetController = TextEditingController(); // Rua (obrigatório)
  final _numberController = TextEditingController(); // Número (obrigatório)
  final _neighborhoodController = TextEditingController(); // Bairro (obrigatório)
  final _cityController = TextEditingController(); // Cidade (obrigatório)
  final _stateController = TextEditingController(); // UF (obrigatório)
  final _complementController = TextEditingController(); // Complemento (opcional)

  // Selected values
  String? _accountStatus;
  int _currentStep = 0; // 0: formulário, 1: instruções, 2: aguardando aprovação, 3: confirmar aprovação

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _businessNameController.dispose();
    _emailController.dispose();
    _taxIdController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _personNameController.dispose();
    _personEmailController.dispose();
    _personCpfController.dispose();
    _motherNameController.dispose();
    _cepController.dispose();
    _streetController.dispose();
    _numberController.dispose();
    _neighborhoodController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _complementController.dispose();
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadData() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      await _apiService.loadToken();
      
      // Buscar status da conta PagBank
      final statusResponse = await _apiService.getPagBankAccountStatus();
      if (statusResponse['success']) {
        final data = statusResponse['data'];
        _accountStatus = data['status'];
        final registrationData = data['registration_data'] as Map<String, dynamic>?;
        
        if (registrationData != null) {
          _nameController.text = registrationData['name'] ?? '';
          _businessNameController.text = registrationData['business_name'] ?? '';
          _emailController.text = registrationData['email'] ?? '';
          _taxIdController.text = registrationData['tax_id'] ?? '';
          _phoneController.text = registrationData['phone'] ?? '';
          _birthDateController.text = registrationData['birth_date'] ?? '';
          
          final address = registrationData['address'] as Map<String, dynamic>?;
          if (address != null) {
            _cepController.text = address['postal_code'] ?? '';
            _streetController.text = address['street'] ?? '';
            _numberController.text = address['number'] ?? '';
            _neighborhoodController.text = address['district'] ?? address['locality'] ?? '';
            _cityController.text = address['city'] ?? '';
            _stateController.text = address['state'] ?? address['region_code'] ?? '';
            _complementController.text = address['complement'] ?? '';
          }
          
          // Carregar dados da pessoa física
          final person = registrationData['person'] as Map<String, dynamic>?;
          if (person != null) {
            _personNameController.text = person['name'] ?? '';
            _personEmailController.text = person['email'] ?? '';
            _personCpfController.text = person['tax_id'] ?? '';
            _motherNameController.text = person['mother_name'] ?? '';
          }
        }
        
        // Definir step baseado no status
        if (_accountStatus == 'approved' && data['approved_by_workshop'] == false) {
          _currentStep = 3; // Confirmar aprovação
        } else if (_accountStatus == 'in_analysis' || _accountStatus == 'pending') {
          _currentStep = 2; // Aguardando aprovação
        } else if (_accountStatus == 'not_created' || _accountStatus == null) {
          _currentStep = 0; // Formulário
        }
      }
      
      _safeSetState(() {
        _isLoading = false;
      });
    } catch (e) {
      _safeSetState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados: $e')),
        );
      }
    }
  }

  Future<void> _fetchCep() async {
    final cep = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cep.length != 8) return;

    try {
      final response = await _apiService.getCepData(cep);
      if (response['success'] && response['data'] != null) {
        final data = response['data'];
        _streetController.text = data['logradouro'] ?? '';
        _neighborhoodController.text = data['bairro'] ?? '';
        _cityController.text = data['localidade'] ?? '';
        _stateController.text = data['uf'] ?? '';
      }
    } catch (e) {
      // Ignorar erro de CEP
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    _safeSetState(() => _isSaving = true);

    try {
      // Payload conforme documentação oficial PagBank e payload do Postman que funcionou
      // https://developer.pagbank.com.br/reference/criar-conta
      // Campos obrigatórios para SELLER:
      // - type: "SELLER"
      // - business_category: enum (VEHICLE_SERVICES)
      // - name: string (Nome da pessoa ou Razão Social)
      // - email: string
      // - tax_id: string (CPF 11 dígitos ou CNPJ 14 dígitos)
      // - address: objeto (street, number, complement, locality, city, region_code, country, postal_code)
      // - phones: array [{country: '55', area, number}]
      // - person: objeto (OBRIGATÓRIO para SELLER) com name, email, tax_id (CPF), phones, address, mother_name
      // - tos_acceptance: objeto (OBRIGATÓRIO) com date, user_ip, user_agent
      
      final taxIdDigits = _taxIdController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      
      // Validar telefone
      if (phoneDigits.isEmpty) {
        throw Exception('Telefone é obrigatório');
      }
      
      // Extrair DDD (2 dígitos) e número (8-9 dígitos)
      String phoneArea;
      String phoneNumber;
      
      if (phoneDigits.length >= 10) {
        // Tem DDD: pegar últimos 10 dígitos (DDD + número)
        final last10 = phoneDigits.substring(phoneDigits.length - 10);
        phoneArea = last10.substring(0, 2);
        phoneNumber = last10.substring(2); // 8 dígitos
      } else if (phoneDigits.length >= 8) {
        // Só tem número (8-9 dígitos)
        phoneArea = '11'; // Default
        phoneNumber = phoneDigits;
      } else {
        throw Exception('Telefone deve ter pelo menos 8 dígitos');
      }
      
      // Garantir que phoneNumber tem 8-9 dígitos (sem DDD)
      if (phoneNumber.length < 8 || phoneNumber.length > 9) {
        throw Exception('Número de telefone deve ter 8 ou 9 dígitos (sem DDD)');
      }
      final postalCode = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final regionCode = _stateController.text.trim().toUpperCase().substring(0, _stateController.text.trim().length > 2 ? 2 : _stateController.text.trim().length);
      
      // Converter data de nascimento para YYYY-MM-DD (formato OBRIGATÓRIO do PagBank)
      String? birthDateFormatted;
      if (_birthDateController.text.trim().isNotEmpty) {
        final birthDate = _birthDateController.text.trim();
        // Se está no formato DD/MM/AAAA, converter para YYYY-MM-DD
        if (birthDate.contains('/')) {
          final parts = birthDate.split('/');
          if (parts.length == 3) {
            final day = parts[0].padLeft(2, '0');
            final month = parts[1].padLeft(2, '0');
            final year = parts[2];
            birthDateFormatted = '$year-$month-$day'; // YYYY-MM-DD
          }
        } 
        // Se está no formato DDMMAAAA (sem separador), converter
        else if (RegExp(r'^\d{8}$').hasMatch(birthDate)) {
          final day = birthDate.substring(0, 2);
          final month = birthDate.substring(2, 4);
          final year = birthDate.substring(4, 8);
          birthDateFormatted = '$year-$month-$day'; // YYYY-MM-DD
        }
        // Se já está no formato YYYY-MM-DD, usar direto
        else if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(birthDate)) {
          birthDateFormatted = birthDate;
        }
      }
      
      // CPF da pessoa física (obrigatório para person)
      final personCpf = _personCpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      // Se não preencheu CPF da pessoa, usar o tax_id se for CPF (11 dígitos)
      // Se for CNPJ, não pode usar - precisa preencher o CPF da pessoa
      final personCpfFinal = personCpf.isNotEmpty 
          ? personCpf 
          : (taxIdDigits.length == 11 ? taxIdDigits : '');
      
      // Validar se tem CPF válido para person
      if (personCpfFinal.isEmpty || personCpfFinal.length != 11) {
        throw Exception('CPF da pessoa física é obrigatório e deve ter 11 dígitos');
      }
      
      // Nome da pessoa física (obrigatório para person)
      final personName = _personNameController.text.trim().isNotEmpty 
          ? _personNameController.text.trim() 
          : _nameController.text.trim();
      
      // Email da pessoa física (obrigatório para person)
      final personEmail = _personEmailController.text.trim().isNotEmpty 
          ? _personEmailController.text.trim() 
          : _emailController.text.trim();
      
      // Nome da mãe (obrigatório para person)
      final motherName = _motherNameController.text.trim();
      if (motherName.isEmpty) {
        throw Exception('Nome da mãe é obrigatório');
      }
      
      final registrationData = {
        'type': 'SELLER', // OBRIGATÓRIO
        'business_category': 'VEHICLE_SERVICES', // OBRIGATÓRIO para SELLER
        'name': _nameController.text.trim(), // Nome/Razão Social (obrigatório)
        'email': _emailController.text.trim(), // Email (obrigatório)
        'tax_id': taxIdDigits, // CPF/CNPJ (obrigatório)
        'phone': phoneDigits, // Telefone como string (obrigatório para validação da API)
        'phones': [
          {
            'country': '55',
            'area': phoneArea,
            'number': phoneNumber,
          },
        ],
        'address': {
          'street': _streetController.text.trim(),
          'number': _numberController.text.trim(),
          'complement': _complementController.text.trim(),
          'locality': _neighborhoodController.text.trim(),
          'city': _cityController.text.trim(),
          'region_code': regionCode,
          'country': 'BRA',
          'postal_code': postalCode,
        },
        // person é OBRIGATÓRIO para SELLER
        'person': {
          'name': personName,
          'email': personEmail,
          'tax_id': personCpfFinal, // CPF da pessoa física (11 dígitos) - obrigatório
          'birth_date': birthDateFormatted,
          'mother_name': motherName, // OBRIGATÓRIO: nome da mãe como aparece no documento
          'phones': [
            {
              'country': '55',
              'area': phoneArea,
              'number': phoneNumber,
              'type': 'MOBILE', // OBRIGATÓRIO: deve ser MOBILE
            },
          ],
          'address': {
            'street': _streetController.text.trim(),
            'number': _numberController.text.trim(),
            'complement': _complementController.text.trim(),
            'locality': _neighborhoodController.text.trim(),
            'city': _cityController.text.trim(),
            'region_code': regionCode,
            'country': 'BRA',
            'postal_code': postalCode,
          },
        },
        // tos_acceptance é OBRIGATÓRIO
        'tos_acceptance': {
          'date': DateTime.now().toUtc().toIso8601String(),
          'user_ip': '192.168.1.1', // Será substituído pela API com o IP real
          'user_agent': 'MECA-App-Oficina/1.0',
        },
      };

      // Campos opcionais
      if (_businessNameController.text.trim().isNotEmpty) {
        registrationData['business_name'] = _businessNameController.text.trim(); // Nome fantasia (opcional)
      }
      
      // NÃO adicionar birth_date no nível raiz - apenas em person.birth_date
      // O PagBank exige que birth_date esteja APENAS dentro de person
      // O birth_date já está sendo adicionado em person.birth_date acima, então não precisa adicionar aqui

      final response = await _apiService.createPagBankAccount(registrationData);
      
      if (response['success']) {
        _safeSetState(() {
          _currentStep = 1; // Mostrar instruções
          _accountStatus = 'pending';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Conta PagBank criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception(response['error'] ?? 'Erro ao criar conta');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  Future<void> _confirmApproval() async {
    _safeSetState(() => _isSaving = true);
    
    try {
      final response = await _apiService.confirmPagBankApproval();
      if (response['success']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aprovação confirmada! Sua conta está pronta para receber pagamentos.'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        throw Exception(response['error'] ?? 'Erro ao confirmar aprovação');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  Future<void> _openPagBankApp() async {
    const url = 'https://pagseguro.uol.com.br/app';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o app PagBank')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final textColor = isDark ? Colors.white : Colors.black87;
    final backgroundColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final cardColor = isDark ? const Color(0xFF2D2D2D) : Colors.grey[50];

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          title: const Text('Cadastro PagBank'),
          backgroundColor: const Color(0xFF00C977),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Dados para Cadastro PagBank'),
        backgroundColor: const Color(0xFF00C977),
      ),
      body: _buildBodyContent(isDark, textColor, backgroundColor, cardColor as Color),
    );
  }

  Color _getSecondaryText(bool isDark) {
    return isDark ? const Color(0xFFBDBDBD) : const Color(0xFF757575);
  }

  Widget _buildBodyContent(bool isDark, Color textColor, Color backgroundColor, Color cardColor) {
    final secondaryText = _getSecondaryText(isDark);
    if (_currentStep == 0) {
      return _buildForm(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 1) {
      return _buildInstructions(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 2) {
      return _buildWaitingApproval(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else {
      return _buildConfirmApproval(isDark, textColor, secondaryText, backgroundColor, cardColor);
    }
  }

  Widget _buildForm(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informações da Empresa',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Preencha os dados para criar sua conta PagBank',
              style: TextStyle(fontSize: 16, color: secondaryText),
            ),
            const SizedBox(height: 32),
            
            // Nome/Razão Social (obrigatório)
            _buildSectionTitle('Nome/Razão Social', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _nameController,
              label: 'Nome/Razão Social',
              hint: 'Ex: Oficina MECA LTDA',
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 24),
            
            // Nome Fantasia (opcional)
            _buildSectionTitle('Nome Fantasia (opcional)', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _businessNameController,
              label: 'Nome Fantasia',
              hint: 'Ex: Oficina MECA',
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 24),
            
            // Email (obrigatório)
            _buildSectionTitle('Email', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _emailController,
              label: 'Email',
              hint: 'exemplo@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.isEmpty == true) return 'Campo obrigatório';
                if (!v!.contains('@')) return 'Email inválido';
                return null;
              },
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 24),
            
            // CPF ou CNPJ (obrigatório)
            _buildSectionTitle('CPF ou CNPJ', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _taxIdController,
              label: 'CPF ou CNPJ',
              hint: '000.000.000-00 ou 00.000.000/0000-00',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Campo obrigatório';
                final digits = v!.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length != 11 && digits.length != 14) return 'CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos';
                return null;
              },
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 24),
            
            // Telefone (obrigatório)
            _buildSectionTitle('Telefone', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _phoneController,
              label: 'Telefone',
              hint: '(11) 99999-9999',
              keyboardType: TextInputType.phone,
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 24),
            
            // Data de Nascimento (opcional, recomendado)
            _buildSectionTitle('Data de Nascimento (opcional)', textColor),
            const SizedBox(height: 12),
            _buildInputField(
              controller: _birthDateController,
              label: 'Data de Nascimento',
              hint: 'DD/MM/AAAA',
              keyboardType: TextInputType.datetime,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 32),
            
            // Informações da Pessoa Física (obrigatório para SELLER)
            Text(
              'Informações da Pessoa Física',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Dados do responsável pela conta (obrigatório)',
              style: TextStyle(fontSize: 14, color: secondaryText),
            ),
            const SizedBox(height: 24),
            
            // Nome da Pessoa Física
            _buildInputField(
              controller: _personNameController,
              label: 'Nome Completo',
              hint: 'Ex: João Silva',
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 16),
            
            // Email da Pessoa Física
            _buildInputField(
              controller: _personEmailController,
              label: 'Email',
              hint: 'exemplo@email.com',
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.isEmpty == true) return 'Campo obrigatório';
                if (!v!.contains('@')) return 'Email inválido';
                return null;
              },
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 16),
            
            // CPF da Pessoa Física
            _buildInputField(
              controller: _personCpfController,
              label: 'CPF',
              hint: '000.000.000-00',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty == true) return 'Campo obrigatório';
                final digits = v!.replaceAll(RegExp(r'[^0-9]'), '');
                if (digits.length != 11) return 'CPF deve ter 11 dígitos';
                return null;
              },
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 16),
            
            // Nome da Mãe
            _buildInputField(
              controller: _motherNameController,
              label: 'Nome da Mãe',
              hint: 'Nome completo como aparece no documento',
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 32),
            
            // Endereço
            Text(
              'Endereço',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 24),
            
            // CEP
            _buildInputField(
              controller: _cepController,
              label: 'CEP',
              hint: '00000-000',
              keyboardType: TextInputType.number,
              onChanged: (_) => _fetchCep(),
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    controller: _streetController,
                    label: 'Rua',
                    hint: 'Nome da rua',
                    validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
                    textColor: textColor,
                    secondaryText: secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _numberController,
                    label: 'Número',
                    hint: '123',
                    validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
                    textColor: textColor,
                    secondaryText: secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInputField(
              controller: _neighborhoodController,
              label: 'Bairro',
              hint: 'Nome do bairro',
              validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _buildInputField(
                    controller: _cityController,
                    label: 'Cidade',
                    hint: 'Nome da cidade',
                    validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
                    textColor: textColor,
                    secondaryText: secondaryText,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _stateController,
                    label: 'UF',
                    hint: 'SP',
                    maxLength: 2,
                    textCapitalization: TextCapitalization.characters,
                    validator: (v) => v?.isEmpty == true ? 'Campo obrigatório' : null,
                    textColor: textColor,
                    secondaryText: secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            _buildInputField(
              controller: _complementController,
              label: 'Complemento (opcional)',
              hint: 'Apto, bloco, etc.',
              textColor: textColor,
              secondaryText: secondaryText,
            ),
            const SizedBox(height: 32),
            
            // Botão salvar
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveAccount,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text(
                        'Criar Conta PagBank',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructions(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 64),
          const SizedBox(height: 16),
          Text(
            'Conta Criada com Sucesso!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Agora siga os passos abaixo para validar sua conta',
            style: TextStyle(fontSize: 16, color: secondaryText),
          ),
          const SizedBox(height: 32),
          
          _buildStepCard(
            step: 1,
            title: 'Baixe o App PagBank',
            description: 'Instale o aplicativo PagBank no seu celular através da App Store ou Google Play',
            icon: Icons.download,
            textColor: textColor,
            secondaryText: secondaryText,
            cardColor: cardColor,
            onTap: _openPagBankApp,
          ),
          const SizedBox(height: 16),
          
          _buildStepCard(
            step: 2,
            title: 'Faça Login',
            description: 'Entre no app usando o email e senha que você cadastrou',
            icon: Icons.login,
            textColor: textColor,
            secondaryText: secondaryText,
            cardColor: cardColor,
          ),
          const SizedBox(height: 16),
          
          _buildStepCard(
            step: 3,
            title: 'Complete a Validação',
            description: 'Siga as instruções no app para validar sua conta e documentos',
            icon: Icons.verified_user,
            textColor: textColor,
            secondaryText: secondaryText,
            cardColor: cardColor,
          ),
          const SizedBox(height: 16),
          
          _buildStepCard(
            step: 4,
            title: 'Aguarde Análise',
            description: 'A equipe PagBank vai analisar sua conta. Isso pode levar alguns dias úteis',
            icon: Icons.hourglass_empty,
            textColor: textColor,
            secondaryText: secondaryText,
            cardColor: cardColor,
          ),
          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () {
                _safeSetState(() => _currentStep = 2);
                _loadData();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Entendi, vou aguardar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingApproval(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hourglass_empty, color: Colors.orange, size: 80),
          const SizedBox(height: 24),
          Text(
            'Aguardando Aprovação',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua conta está sendo analisada pela equipe PagBank',
            style: TextStyle(fontSize: 16, color: secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'O que acontece agora?',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'A equipe PagBank está analisando seus dados e documentos. Você será notificado quando sua conta for aprovada.',
                  style: TextStyle(fontSize: 14, color: secondaryText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: OutlinedButton(
              onPressed: _loadData,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF00C977)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Atualizar Status',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF00C977)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmApproval(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            'Conta Aprovada!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua conta PagBank foi aprovada pela equipe PagBank',
            style: TextStyle(fontSize: 16, color: secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Próximos Passos',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                ),
                const SizedBox(height: 16),
                Text(
                  'Confirme a aprovação abaixo para ativar sua conta e começar a receber pagamentos.',
                  style: TextStyle(fontSize: 14, color: secondaryText),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _confirmApproval,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Confirmar Aprovação',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int step,
    required String title,
    required String description,
    required IconData icon,
    required Color textColor,
    required Color secondaryText,
    required Color cardColor,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF00C977).withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF00C977).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  '$step',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00C977),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(fontSize: 14, color: secondaryText),
                  ),
                ],
              ),
            ),
            Icon(icon, color: const Color(0xFF00C977)),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, Color textColor) {
    return Text(
      title,
      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    int? maxLength,
    TextCapitalization textCapitalization = TextCapitalization.none,
    required Color textColor,
    required Color secondaryText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: TextStyle(color: textColor),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: secondaryText),
        hintStyle: TextStyle(color: secondaryText.withOpacity(0.5)),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: secondaryText.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
        ),
      ),
    );
  }

}

