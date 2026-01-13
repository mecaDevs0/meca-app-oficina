import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../utils/phone_formatter.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/cnpj_formatter.dart';
import '../../utils/email_formatter.dart';
import '../../utils/cep_formatter.dart';
import '../../utils/date_formatter.dart';

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
  int _currentStep = 0; // 0: escolha (criar/vincular), 1: formulário, 2: instruções, 3: aguardando aprovação, 4: confirmar aprovação
  bool _isConnectingOAuth = false;
  bool _hasExistingData = false; // Indica se já tem dados cadastrados (mas não validado)

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
      
      // Verificar se tem workshopId antes de fazer a chamada
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        _safeSetState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token inválido ou workshopId não encontrado. Faça login novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      
      // Buscar status da conta PagBank
      final statusResponse = await _apiService.getPagBankAccountStatus();
      if (statusResponse['success']) {
        final data = statusResponse['data'];
        _accountStatus = data['status'];
        final registrationData = data['registration_data'] as Map<String, dynamic>?;
        final hasAccountId = data['pagbank_account_id'] != null;
        
        if (registrationData != null) {
          _nameController.text = registrationData['name'] ?? '';
          _businessNameController.text = registrationData['business_name'] ?? '';
          // Formatar email ao carregar
          final emailValue = registrationData['email'] ?? '';
          _emailController.text = emailValue.toString().trim().toLowerCase();
          // Formatar CPF/CNPJ ao carregar
          final taxIdValue = registrationData['tax_id'] ?? '';
          if (taxIdValue.toString().isNotEmpty) {
            final digits = taxIdValue.toString().replaceAll(RegExp(r'\D'), '');
            if (digits.length == 11) {
              _taxIdController.text = CpfFormatter().formatEditUpdate(
                const TextEditingValue(),
                TextEditingValue(text: digits),
              ).text;
            } else if (digits.length == 14) {
              _taxIdController.text = CnpjFormatter().formatEditUpdate(
                const TextEditingValue(),
                TextEditingValue(text: digits),
              ).text;
            } else {
              _taxIdController.text = taxIdValue.toString();
            }
          }
          // Formatar telefone ao carregar
          // Pode vir como string de números ou como objeto phones
          String phoneValue = '';
          if (registrationData['phone'] != null) {
            phoneValue = registrationData['phone'].toString();
          } else if (registrationData['phones'] != null && (registrationData['phones'] as List).isNotEmpty) {
            // Se não tem phone direto, tentar pegar do array phones
            final phones = registrationData['phones'] as List;
            if (phones.isNotEmpty) {
              final firstPhone = phones[0] as Map<String, dynamic>?;
              if (firstPhone != null) {
                final area = firstPhone['area']?.toString() ?? '';
                final number = firstPhone['number']?.toString() ?? '';
                phoneValue = '$area$number';
              }
            }
          }
          if (phoneValue.isNotEmpty) {
            final phoneDigits = phoneValue.replaceAll(RegExp(r'\D'), '');
            if (phoneDigits.isNotEmpty) {
              _phoneController.text = PhoneInputFormatter().formatEditUpdate(
                const TextEditingValue(),
                TextEditingValue(text: phoneDigits),
              ).text;
            }
          }
          // Formatar data de nascimento ao carregar
          final birthDateValue = registrationData['birth_date'] ?? '';
          if (birthDateValue.toString().isNotEmpty) {
            // Se está no formato YYYY-MM-DD, converter para DD/MM/AAAA
            if (birthDateValue.toString().contains('-')) {
              final parts = birthDateValue.toString().split('-');
              if (parts.length == 3) {
                _birthDateController.text = '${parts[2]}/${parts[1]}/${parts[0]}';
              } else {
                _birthDateController.text = birthDateValue.toString();
              }
            } else {
              // Se já está formatado, usar direto
              _birthDateController.text = birthDateValue.toString();
            }
          }
          
          final address = registrationData['address'] as Map<String, dynamic>?;
          if (address != null) {
            // Formatar CEP ao carregar
            final cepValue = address['postal_code'] ?? '';
            if (cepValue.toString().isNotEmpty) {
              final cepDigits = cepValue.toString().replaceAll(RegExp(r'\D'), '');
              if (cepDigits.length == 8) {
                _cepController.text = CepFormatter().formatEditUpdate(
                  const TextEditingValue(),
                  TextEditingValue(text: cepDigits),
                ).text;
              } else {
                _cepController.text = cepValue.toString();
              }
            }
            _streetController.text = address['street'] ?? address['logradouro'] ?? '';
            _numberController.text = address['number'] ?? address['numero'] ?? '';
            _neighborhoodController.text = address['district'] ?? address['bairro'] ?? address['neighborhood'] ?? address['locality'] ?? '';
            _cityController.text = address['city'] ?? address['cidade'] ?? '';
            // UF pode vir como state, estado, ou region_code
            final stateValue = address['state'] ?? address['estado'] ?? address['region_code'] ?? '';
            _stateController.text = stateValue.toString().toUpperCase().substring(0, stateValue.toString().length > 2 ? 2 : stateValue.toString().length);
            _complementController.text = address['complement'] ?? address['complemento'] ?? '';
          }
          
          // Carregar dados da pessoa física
          final person = registrationData['person'] as Map<String, dynamic>?;
          if (person != null) {
            _personNameController.text = person['name'] ?? '';
            // Formatar email da pessoa física ao carregar
            final personEmailValue = person['email'] ?? '';
            _personEmailController.text = personEmailValue.toString().trim().toLowerCase();
            // Formatar CPF da pessoa física ao carregar
            final personCpfValue = person['tax_id'] ?? '';
            if (personCpfValue.toString().isNotEmpty) {
              final cpfDigits = personCpfValue.toString().replaceAll(RegExp(r'\D'), '');
              if (cpfDigits.length == 11) {
                _personCpfController.text = CpfFormatter().formatEditUpdate(
                  const TextEditingValue(),
                  TextEditingValue(text: cpfDigits),
                ).text;
              } else {
                _personCpfController.text = personCpfValue.toString();
              }
            }
            _motherNameController.text = person['mother_name'] ?? '';
            
            // Carregar data de nascimento da pessoa se não estiver no nível raiz
            if (_birthDateController.text.isEmpty && person['birth_date'] != null) {
              final personBirthDate = person['birth_date'].toString();
              if (personBirthDate.isNotEmpty) {
                if (personBirthDate.contains('-')) {
                  final parts = personBirthDate.split('-');
                  if (parts.length == 3) {
                    _birthDateController.text = '${parts[2]}/${parts[1]}/${parts[0]}';
                  }
                } else {
                  _birthDateController.text = personBirthDate;
                }
              }
            }
          }
        }
        
        // Verificar se já tem conta conectada via OAuth
        final hasOAuthConnection = data['pagbank_account_id'] != null && 
                                   data['pagbank_access_token'] != null;
        final isVerified = data['pagbank_verified'] == true;
        
        // Verificar se já tem dados cadastrados (registration_data)
        // Considera que tem dados se tem registration_data OU account_id (mesmo que não validado)
        _hasExistingData = (registrationData != null && registrationData.isNotEmpty) || hasAccountId;

        // Definir step baseado no status
        if (isVerified && hasOAuthConnection) {
          // Conta já conectada e verificada - não precisa fazer nada
          _currentStep = -1; // Tela de sucesso
        } else if (_accountStatus == 'approved' && data['approved_by_workshop'] == false) {
          _currentStep = 4; // Confirmar aprovação
        } else if (_accountStatus == 'in_analysis' || _accountStatus == 'pending') {
          _currentStep = 3; // Aguardando aprovação
        } else if (hasOAuthConnection && !isVerified) {
          _currentStep = 0; // Escolher ação (já conectado, precisa validar)
        } else if (_hasExistingData && !isVerified) {
          // Tem dados cadastrados mas não está validado - mostrar opção de editar
          _currentStep = 1; // Ir direto para formulário para editar
        } else if (_accountStatus == 'not_created' || _accountStatus == null) {
          _currentStep = 0; // Escolher ação (criar ou vincular)
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
    // Validar formulário primeiro
    if (!_formKey.currentState!.validate()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, corrija os erros no formulário antes de salvar.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    _safeSetState(() => _isSaving = true);

    try {
      // Validação completa de todos os campos obrigatórios ANTES de enviar
      final taxIdDigits = _taxIdController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final phoneDigits = _phoneController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final postalCode = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final name = _nameController.text.trim();
      final email = _emailController.text.trim();
      final street = _streetController.text.trim();
      final number = _numberController.text.trim();
      final neighborhood = _neighborhoodController.text.trim();
      final city = _cityController.text.trim();
      final state = _stateController.text.trim();
      final motherName = _motherNameController.text.trim();
      
      // Debug: verificar valores antes de validar
      print('🔍 [PagBank Save] Valores dos campos:');
      print('  name: "$name" (isEmpty: ${name.isEmpty})');
      print('  email: "$email" (isEmpty: ${email.isEmpty})');
      print('  taxIdDigits: "$taxIdDigits" (length: ${taxIdDigits.length})');
      print('  phoneDigits: "$phoneDigits" (length: ${phoneDigits.length})');
      print('  postalCode: "$postalCode" (length: ${postalCode.length})');
      print('  street: "$street" (isEmpty: ${street.isEmpty})');
      print('  number: "$number" (isEmpty: ${number.isEmpty})');
      print('  neighborhood: "$neighborhood" (isEmpty: ${neighborhood.isEmpty})');
      print('  city: "$city" (isEmpty: ${city.isEmpty})');
      print('  state: "$state" (length: ${state.length})');
      print('  motherName: "$motherName" (isEmpty: ${motherName.isEmpty})');
      
      // Lista de erros de validação
      final List<String> validationErrors = [];
      
      // Validar campos básicos
      if (name.isEmpty) validationErrors.add('Nome/Razão Social é obrigatório');
      if (email.isEmpty) validationErrors.add('Email é obrigatório');
      if (taxIdDigits.isEmpty) {
        validationErrors.add('CPF/CNPJ é obrigatório');
      } else if (taxIdDigits.length != 11 && taxIdDigits.length != 14) {
        validationErrors.add('CPF deve ter 11 dígitos ou CNPJ deve ter 14 dígitos');
      }
      
      // Validar telefone
      if (phoneDigits.isEmpty) {
        validationErrors.add('Telefone é obrigatório');
      } else if (phoneDigits.length < 8) {
        validationErrors.add('Telefone deve ter pelo menos 8 dígitos');
      }
      
      // Validar endereço
      if (postalCode.isEmpty) {
        validationErrors.add('CEP é obrigatório');
      } else if (postalCode.length != 8) {
        validationErrors.add('CEP deve ter 8 dígitos');
      }
      if (street.isEmpty) validationErrors.add('Rua é obrigatória');
      if (number.isEmpty) validationErrors.add('Número é obrigatório');
      if (neighborhood.isEmpty) validationErrors.add('Bairro é obrigatório');
      if (city.isEmpty) validationErrors.add('Cidade é obrigatória');
      if (state.isEmpty) {
        validationErrors.add('UF é obrigatória');
      } else if (state.length != 2) {
        validationErrors.add('UF deve ter 2 caracteres');
      }
      
      // Validar dados da pessoa física (person)
      final personCpf = _personCpfController.text.replaceAll(RegExp(r'[^0-9]'), '');
      final personCpfFinal = personCpf.isNotEmpty 
          ? personCpf 
          : (taxIdDigits.length == 11 ? taxIdDigits : '');
      
      print('  personCpf: "$personCpf" (length: ${personCpf.length})');
      print('  personCpfFinal: "$personCpfFinal" (length: ${personCpfFinal.length})');
      print('  motherName: "$motherName" (isEmpty: ${motherName.isEmpty})');
      
      if (personCpfFinal.isEmpty || personCpfFinal.length != 11) {
        validationErrors.add('CPF da pessoa física é obrigatório e deve ter 11 dígitos');
      }
      
      if (motherName.isEmpty) {
        validationErrors.add('Nome da mãe é obrigatório');
      } else {
        // PagBank exige que o nome da mãe tenha mais de uma palavra
        final motherNameWords = motherName.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
        if (motherNameWords.length < 2) {
          validationErrors.add('Nome da mãe deve possuir mais de uma palavra (ex: Maria Silva)');
        }
      }
      
      // Debug: mostrar erros encontrados
      if (validationErrors.isNotEmpty) {
        print('❌ [PagBank Save] Erros de validação encontrados:');
        for (var error in validationErrors) {
          print('  - $error');
        }
      } else {
        print('✅ [PagBank Save] Todos os campos validados com sucesso!');
      }
      
      // Se houver erros de validação, mostrar todos de uma vez
      if (validationErrors.isNotEmpty) {
        throw Exception('Por favor, corrija os seguintes campos:\n${validationErrors.join('\n')}');
      }
      
      // Extrair DDD (2 dígitos) e número (8-9 dígitos)
      String phoneArea;
      String phoneNumber;
      
      if (phoneDigits.length >= 10) {
        // Tem DDD: pegar últimos 10 ou 11 dígitos (DDD + número)
        final lastDigits = phoneDigits.length >= 11 
            ? phoneDigits.substring(phoneDigits.length - 11) // 11 dígitos (DDD + 9 dígitos)
            : phoneDigits.substring(phoneDigits.length - 10); // 10 dígitos (DDD + 8 dígitos)
        phoneArea = lastDigits.substring(0, 2);
        phoneNumber = lastDigits.substring(2);
        
        // Garantir que phoneNumber tem 9 dígitos (formato MOBILE do PagBank)
        if (phoneNumber.length == 8) {
          phoneNumber = '9' + phoneNumber; // Adicionar 9 no início para celular
        } else if (phoneNumber.length > 9) {
          phoneNumber = phoneNumber.substring(phoneNumber.length - 9); // Pegar últimos 9 dígitos
        }
      } else if (phoneDigits.length >= 8) {
        // Só tem número (8-9 dígitos)
        phoneArea = '11'; // Default
        phoneNumber = phoneDigits;
        
        // Garantir que phoneNumber tem 9 dígitos
        if (phoneNumber.length == 8) {
          phoneNumber = '9' + phoneNumber; // Adicionar 9 no início para celular
        } else if (phoneNumber.length > 9) {
          phoneNumber = phoneNumber.substring(phoneNumber.length - 9); // Pegar últimos 9 dígitos
        }
      } else {
        throw Exception('Telefone deve ter pelo menos 8 dígitos');
      }
      
      // Validar que phoneNumber tem exatamente 9 dígitos (formato MOBILE do PagBank)
      if (phoneNumber.length != 9) {
        throw Exception('Número de telefone deve ter 9 dígitos (formato MOBILE)');
      }
      
      final regionCode = state.toUpperCase().substring(0, 2);
      
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
      
      // Nome da pessoa física (obrigatório para person)
      final personName = _personNameController.text.trim().isNotEmpty 
          ? _personNameController.text.trim() 
          : name;
      
      // Email da pessoa física (obrigatório para person)
      final personEmail = _personEmailController.text.trim().isNotEmpty 
          ? _personEmailController.text.trim() 
          : email;
      
      final registrationData = {
        'type': 'SELLER', // OBRIGATÓRIO
        'business_category': 'VEHICLE_SERVICES', // OBRIGATÓRIO para SELLER
        'name': name, // Nome/Razão Social (obrigatório)
        'email': email, // Email (obrigatório)
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
          'street': street,
          'number': number,
          'complement': _complementController.text.trim(),
          'locality': neighborhood,
          'city': city,
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
            'street': street,
            'number': number,
            'complement': _complementController.text.trim(),
            'locality': neighborhood,
            'city': city,
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
        final data = response['data'];
        
        // Verificar se a conta já existe e precisa de OAuth Connect
        if (data['needs_oauth_connect'] == true || data['account_exists'] == true) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(data['message'] ?? 'Conta já existe. Use "Vincular Conta Existente" para conectar.'),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 5),
              ),
            );
            
            // Voltar para tela de escolha para mostrar opção de vincular
            _safeSetState(() {
              _currentStep = 0;
            });
          }
          return;
        }
        
        _safeSetState(() {
          _currentStep = 2; // Mostrar instruções
          _accountStatus = 'pending';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Conta PagBank criada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        // Extrair mensagem de erro mais detalhada
        final errorMessage = response['error'] ?? response['message'] ?? 'Erro ao criar conta';
        final errorDetails = response['details'];
        String fullErrorMessage = errorMessage;
        
        if (errorDetails != null) {
          if (errorDetails is Map && errorDetails['message'] != null) {
            fullErrorMessage = '${errorMessage}\n${errorDetails['message']}';
          } else if (errorDetails is String) {
            fullErrorMessage = '${errorMessage}\n$errorDetails';
          }
        }
        
        throw Exception(fullErrorMessage);
      }
    } catch (e) {
      if (mounted) {
        // Mostrar erro em diálogo para mensagens longas
        final errorText = e.toString().replaceAll('Exception: ', '');
        if (errorText.contains('\n') || errorText.length > 100) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Erro ao criar conta'),
              content: SingleChildScrollView(
                child: Text(errorText),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorText),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        }
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
    if (_currentStep == -1) {
      return _buildAlreadyConnected(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 0) {
      return _buildChoiceScreen(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 1) {
      return _buildForm(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 2) {
      return _buildInstructions(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else if (_currentStep == 3) {
      return _buildWaitingApproval(isDark, textColor, secondaryText, backgroundColor, cardColor);
    } else {
      return _buildConfirmApproval(isDark, textColor, secondaryText, backgroundColor, cardColor);
    }
  }

  Future<void> _linkExistingAccount() async {
    _safeSetState(() => _isConnectingOAuth = true);

    try {
      // Garantir que o token está carregado antes de fazer a chamada
      await _apiService.loadToken();
      
      // Verificar se tem workshopId antes de fazer a chamada
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Token inválido ou workshopId não encontrado. Faça login novamente.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        _safeSetState(() => _isConnectingOAuth = false);
        return;
      }
      
      // Usar startPagBankConnect que é o método correto para iniciar o fluxo OAuth
      final response = await _apiService.startPagBankConnect();
      
      if (response['success']) {
        final data = response['data'];
        // Tentar múltiplos formatos de URL
        final authUrl = data['authorizationUrl'] ?? 
                       data['authorize_url'] ?? 
                       data['url'] ?? 
                       null;
        
        if (authUrl == null || authUrl.toString().isEmpty) {
          throw Exception('URL de autorização não encontrada na resposta da API');
        }
        
        // Validar se a URL é válida
        final urlString = authUrl.toString();
        if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
          throw Exception('URL de autorização inválida: $urlString');
        }
        
        // Verificar se pode abrir a URL
        final uri = Uri.parse(urlString);
        final canLaunch = await canLaunchUrl(uri);
        
        if (!canLaunch) {
          throw Exception('Não foi possível abrir a URL: $urlString');
        }
        
        // Abrir URL em navegador externo (não in-app para evitar problemas de CORS)
        final launched = await launchUrl(
          uri, 
          mode: LaunchMode.externalApplication,
        );
        
        if (launched) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Redirecionando para PagBank... Complete a autorização no navegador.'),
                backgroundColor: Colors.blue,
                duration: Duration(seconds: 5),
              ),
            );
            // Aguardar alguns segundos e recarregar dados
            Future.delayed(const Duration(seconds: 5), () {
              if (mounted) {
                _loadData();
              }
            });
          }
        } else {
          throw Exception('Não foi possível abrir a página de autorização. Verifique sua conexão.');
        }
      } else {
        final errorMessage = response['error'] ?? 'Erro ao obter URL de autorização';
        throw Exception(errorMessage);
      }
    } catch (e) {
      String errorMessage = 'Erro ao vincular conta';
      final errorString = e.toString();
      
      if (errorString.contains('authorizationUrl') || errorString.contains('URL')) {
        errorMessage = 'Erro ao obter URL de autorização. Verifique sua conexão e tente novamente.';
      } else if (errorString.contains('workshopId') || errorString.contains('Token')) {
        errorMessage = 'Erro de autenticação. Faça login novamente.';
      } else if (errorString.contains('404')) {
        errorMessage = 'Endpoint não encontrado. Verifique se a API está atualizada.';
      } else if (errorString.contains('500')) {
        errorMessage = 'Erro no servidor. Tente novamente em alguns instantes.';
      } else {
        errorMessage = 'Erro ao vincular conta: ${errorString.replaceAll('Exception: ', '').replaceAll('Error: ', '')}';
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      _safeSetState(() => _isConnectingOAuth = false);
    }
  }

  Widget _buildChoiceScreen(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conectar Conta PagBank',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Escolha como deseja conectar sua conta PagBank',
            style: TextStyle(fontSize: 16, color: secondaryText),
          ),
          const SizedBox(height: 32),
          
          // Opção 1: Vincular conta existente
          InkWell(
            onTap: _isConnectingOAuth ? null : _linkExistingAccount,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00C977).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.link,
                      color: Color(0xFF00C977),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vincular Conta Existente',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Já tenho uma conta PagBank e quero vincular',
                          style: TextStyle(fontSize: 14, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  if (_isConnectingOAuth)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFF00C977),
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Opção 2: Criar nova conta OU Editar dados existentes
          InkWell(
            onTap: () {
              _safeSetState(() {
                _currentStep = 1; // Ir para formulário
              });
            },
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: const Color(0xFF00C977).withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _hasExistingData ? Icons.edit : Icons.add_circle_outline,
                      color: const Color(0xFF00C977),
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _hasExistingData ? 'Editar Dados Bancários PagBank' : 'Criar Nova Conta',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _hasExistingData 
                            ? 'Editar os dados bancários PagBank já cadastrados'
                            : 'Criar uma nova conta PagBank para minha oficina',
                          style: TextStyle(fontSize: 14, color: secondaryText),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFF00C977),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlreadyConnected(bool isDark, Color textColor, Color secondaryText, Color backgroundColor, Color cardColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 80),
          const SizedBox(height: 24),
          Text(
            'Conta PagBank Conectada!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Sua conta PagBank está conectada e verificada. Você já pode receber pagamentos!',
            style: TextStyle(fontSize: 16, color: secondaryText),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
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
              inputFormatters: [EmailFormatter()],
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
              inputFormatters: [
                // Formatter dinâmico que detecta CPF ou CNPJ
                TextInputFormatter.withFunction((oldValue, newValue) {
                  final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
                  if (digits.length <= 11) {
                    return CpfFormatter().formatEditUpdate(oldValue, newValue);
                  } else {
                    return CnpjFormatter().formatEditUpdate(oldValue, newValue);
                  }
                }),
              ],
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
              inputFormatters: [PhoneInputFormatter()],
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
              inputFormatters: [DateFormatter()],
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
              inputFormatters: [EmailFormatter()],
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
              inputFormatters: [CpfFormatter(), LengthLimitingTextInputFormatter(14)],
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
              inputFormatters: [CepFormatter(), LengthLimitingTextInputFormatter(9)],
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
                    : Text(
                        _hasExistingData ? 'Atualizar Dados PagBank' : 'Criar Conta PagBank',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
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
                _safeSetState(() => _currentStep = 3);
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
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: inputFormatters,
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

