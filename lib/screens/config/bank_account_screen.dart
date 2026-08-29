import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../data/banks_data.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/cnpj_formatter.dart';
import '../../utils/cep_formatter.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingCep = false;
  Map<String, dynamic>? _bankData;
  final ApiService _apiService = ApiService();

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _accountTypeController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _agencyNumberController = TextEditingController();
  final _accountHolderNameController = TextEditingController();
  final _accountHolderDocumentController = TextEditingController();
  final _pixKeyController = TextEditingController();
  final _pixKeyTypeController = TextEditingController();
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _numberController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _complementController = TextEditingController();

  // Selected bank
  BankData? _selectedBank;
  String _selectedAccountType = 'checking';
  String _selectedPixKeyType = 'cpf';

  @override
  void initState() {
    super.initState();
    _loadBankData();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountTypeController.dispose();
    _accountNumberController.dispose();
    _agencyNumberController.dispose();
    _accountHolderNameController.dispose();
    _accountHolderDocumentController.dispose();
    _pixKeyController.dispose();
    _pixKeyTypeController.dispose();
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

  Future<void> _loadBankData() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();

      final response = await _apiService.getBankAccount();
      if (response['success']) {
        _safeSetState(() {
          _bankData = response['data'];
        });
        
        // Preencher campos se já existirem dados
        if (_bankData != null) {
          _bankNameController.text = _bankData!['bank_name'] ?? '';
          _accountTypeController.text = _bankData!['account_type'] ?? '';
          _accountNumberController.text =
              _bankData!['account_number'] ?? _bankData!['account'] ?? '';
          _agencyNumberController.text =
              _bankData!['agency_number'] ?? _bankData!['agency'] ?? '';
          _accountHolderNameController.text = _bankData!['account_holder_name'] ?? '';
          _accountHolderDocumentController.text = _bankData!['account_holder_document'] ?? '';
          _pixKeyController.text = _bankData!['pix_key'] ?? '';
          _pixKeyTypeController.text = _bankData!['pix_key_type'] ?? '';
          _cepController.text = _bankData!['bank_cep'] ?? '';
          _streetController.text = _bankData!['bank_street'] ?? '';
          _numberController.text = _bankData!['bank_number'] ?? '';
          _neighborhoodController.text = _bankData!['bank_neighborhood'] ?? '';
          _cityController.text = _bankData!['bank_city'] ?? '';
          _stateController.text = _bankData!['bank_state'] ?? '';
          _complementController.text = _bankData!['bank_complement'] ?? '';
          
          // Encontrar banco selecionado
          final bankCode = _bankData!['bank_code'];
          if (bankCode != null) {
            _selectedBank = BanksData.getBankByCode(bankCode);
          }

          final accountType = _bankData!['account_type'];
          if (accountType != null && accountType.toString().isNotEmpty) {
            _selectedAccountType = accountType;
          }

          final pixType = _bankData!['pix_key_type'];
          if (pixType != null && pixType.toString().isNotEmpty) {
            _selectedPixKeyType = pixType;
          }

          _safeSetState(() {});
        }
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro ao carregar dados bancários: ${e.toString()}')),
        );
      }
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _saveBankData() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedBank == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione um banco'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    _safeSetState(() => _isSaving = true);
    
    try {
      final response = await _apiService.updateBankAccount(
        bankName: _selectedBank!.name,
        bankCode: _selectedBank!.code,
        accountType: _selectedAccountType,
        accountNumber: _accountNumberController.text,
        agencyNumber: _agencyNumberController.text,
        accountHolderName: _accountHolderNameController.text,
        accountHolderDocument: _accountHolderDocumentController.text,
        pixKey: _pixKeyController.text.isNotEmpty ? _pixKeyController.text : null,
        pixKeyType: _selectedPixKeyType,
        cep: _cepController.text,
        street: _streetController.text,
        number: _numberController.text,
        neighborhood: _neighborhoodController.text,
        city: _cityController.text,
        state: _stateController.text,
        complement: _complementController.text,
      );
      
      if (response['success']) {
        // Aguardar um pouco para garantir que o banco foi atualizado
        await Future.delayed(const Duration(milliseconds: 1000));
        
        // Verificar novamente se os dados foram salvos corretamente
        final verifyResponse = await _apiService.getBankAccount();
        if (verifyResponse['success'] && verifyResponse['data'] != null) {
          final bankData = verifyResponse['data'];
          final bankCode = bankData['bank_code']?.toString().trim() ?? '';
          final agency = bankData['agency']?.toString().trim() ?? '';
          final account = bankData['account']?.toString().trim() ?? '';
          
          if (bankCode.isNotEmpty && agency.isNotEmpty && account.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dados bancários salvos com sucesso!'),
                backgroundColor: Color(0xFF00C977),
              ),
            );
            // Voltar para home e recarregar
            Navigator.pop(context, true); // Passa true para indicar sucesso
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Dados salvos, mas não foram encontrados na verificação. Recarregue a página.'),
                backgroundColor: Color(0xFFF59E0B),
              ),
            );
            Navigator.pop(context, true); // Passa true para indicar sucesso mesmo assim
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Dados bancários salvos com sucesso!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
          // Voltar para home e recarregar
          Navigator.pop(context, true); // Passa true para indicar sucesso
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  Future<void> _fetchAddressByCep() async {
    final cepRaw = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (cepRaw.length != 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um CEP válido com 8 dígitos.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    _safeSetState(() => _isFetchingCep = true);

    try {
      final response = await http.get(Uri.parse('https://viacep.com.br/ws/$cepRaw/json/'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is Map<String, dynamic> && data['erro'] != true) {
          _streetController.text = (data['logradouro'] ?? '').toString();
          _neighborhoodController.text = (data['bairro'] ?? '').toString();
          _cityController.text = (data['localidade'] ?? '').toString();
          _stateController.text = (data['uf'] ?? '').toString();
          _complementController.text = (data['complemento'] ?? '').toString();

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Endereço carregado pelo ViaCEP.'),
              backgroundColor: Color(0xFF10B981),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('CEP não encontrado no ViaCEP.'),
              backgroundColor: Color(0xFFF59E0B),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar CEP: ${response.statusCode}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao buscar CEP: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      _safeSetState(() => _isFetchingCep = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final isDark = themeService.isDarkMode;
    final bgColor = ThemeService.getBackgroundColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Conta bancária'),
        backgroundColor: themeService.isDarkMode
            ? const Color(0xFF0A0A0A)
            : const Color(0xFF00C977),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      'Informações Bancárias',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure sua conta para receber pagamentos',
                      style: TextStyle(
                        fontSize: 16,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // Bank selection
                    _buildSectionTitle('Banco'),
                    const SizedBox(height: 12),
                    _buildBankSelector(),
                    const SizedBox(height: 24),
                    
                    // Account type
                    _buildSectionTitle('Tipo de Conta'),
                    const SizedBox(height: 12),
                    _buildAccountTypeSelector(),
                    const SizedBox(height: 24),
                    
                    // Account details
                    _buildSectionTitle('Dados da Conta'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _accountNumberController,
                      label: 'Número da Conta',
                      hint: 'Digite o número da conta',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Número da conta é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _agencyNumberController,
                      label: 'Agência',
                      hint: 'Digite o número da agência',
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Número da agência é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // Account holder
                    _buildSectionTitle('Titular da Conta'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _accountHolderNameController,
                      label: 'Nome Completo',
                      hint: 'Digite o nome completo do titular',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Nome do titular é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _accountHolderDocumentController,
                      label: 'CPF/CNPJ',
                      hint: 'Digite o CPF ou CNPJ do titular',
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
                          if (digits.length <= 11) {
                            return CpfFormatter().formatEditUpdate(oldValue, newValue);
                          } else {
                            return CnpjFormatter().formatEditUpdate(oldValue, newValue);
                          }
                        }),
                      ],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CPF/CNPJ é obrigatório';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    
                    // PIX
                    _buildSectionTitle('Chave PIX'),
                    const SizedBox(height: 12),
                    _buildPixKeyTypeSelector(),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _pixKeyController,
                      label: 'Chave PIX',
                      hint: 'Digite a chave PIX',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Chave PIX é obrigatória';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    _buildSectionTitle('Endereço bancário'),
                    const SizedBox(height: 12),
                    _buildInputField(
                      controller: _cepController,
                      label: 'CEP',
                      hint: 'Digite o CEP',
                      keyboardType: TextInputType.number,
                      inputFormatters: [CepFormatter(), LengthLimitingTextInputFormatter(9)],
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CEP é obrigatório';
                        }
                        final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
                        if (digits.length != 8) {
                          return 'Informe um CEP válido';
                        }
                        return null;
                      },
                      suffixIcon: _isFetchingCep
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : IconButton(
                              icon: const Icon(Icons.search),
                              onPressed: _isFetchingCep ? null : _fetchAddressByCep,
                            ),
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _streetController,
                      label: 'Endereço',
                      hint: 'Rua ou avenida',
                      textCapitalization: TextCapitalization.words,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _numberController,
                            label: 'Número',
                            hint: 'Número',
                            keyboardType: TextInputType.text,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _neighborhoodController,
                            label: 'Bairro',
                            hint: 'Digite o bairro',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _cityController,
                            label: 'Cidade',
                            hint: 'Digite a cidade',
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 100,
                          child: _buildInputField(
                            controller: _stateController,
                            label: 'UF',
                            hint: 'UF',
                            textCapitalization: TextCapitalization.characters,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildInputField(
                      controller: _complementController,
                      label: 'Complemento',
                      hint: 'Apartamento, sala, referência...',
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 32),
                    
                    // Save button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveBankData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Salvar Dados Bancários',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
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
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
    );
  }

  Widget _buildBankSelector() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return InkWell(
      onTap: () => _showBankSelector(),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: borderColor,
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
                Icons.account_balance,
                color: Color(0xFF00C977),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(
                _selectedBank?.name ?? 'Selecione um banco',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: _selectedBank != null ? textColor : secondaryTextColor,
                ),
              ),
              if (_selectedBank != null)
                Text(
                  'Código: ${_selectedBank!.code}',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_drop_down,
              color: Color(0xFF8B8B8B),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccountTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildAccountTypeOption(
            value: 'checking',
            label: 'Conta Corrente',
            icon: Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildAccountTypeOption(
            value: 'savings',
            label: 'Poupança',
            icon: Icons.savings,
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTypeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedAccountType == value;
    final dark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => _safeSetState(() => _selectedAccountType = value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C977).withOpacity(0.1)
              : (dark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C977) : (dark ? const Color(0xFF333333) : const Color(0xFFDDDDDD)),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00C977) : const Color(0xFF8B8B8B),
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF00C977) : const Color(0xFF8B8B8B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPixKeyTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildPixKeyTypeOption(
            value: 'cpf',
            label: 'CPF',
            icon: Icons.person,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPixKeyTypeOption(
            value: 'cnpj',
            label: 'CNPJ',
            icon: Icons.business,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPixKeyTypeOption(
            value: 'email',
            label: 'E-mail',
            icon: Icons.email,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildPixKeyTypeOption(
            value: 'phone',
            label: 'Telefone',
            icon: Icons.phone,
          ),
        ),
      ],
    );
  }

  Widget _buildPixKeyTypeOption({
    required String value,
    required String label,
    required IconData icon,
  }) {
    final isSelected = _selectedPixKeyType == value;
    final isDark = Provider.of<ThemeService>(context, listen: false).isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final secondaryColor = ThemeService.getSecondaryTextColor(isDark);

    return InkWell(
      onTap: () => _safeSetState(() => _selectedPixKeyType = value),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00C977).withOpacity(0.1) : cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? const Color(0xFF00C977) : borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF00C977) : secondaryColor,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? const Color(0xFF00C977) : const Color(0xFF8B8B8B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool readOnly = false,
    List<TextInputFormatter>? inputFormatters,
  }) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: secondaryTextColor),
            filled: true,
            fillColor: inputColor,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00C977)),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  void _showBankSelector() {
    final dark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: dark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BankSelectorModal(
        selectedBank: _selectedBank,
        onBankSelected: (bank) {
          setState(() => _selectedBank = bank);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class BankSelectorModal extends StatefulWidget {
  final BankData? selectedBank;
  final Function(BankData) onBankSelected;

  const BankSelectorModal({
    Key? key,
    required this.selectedBank,
    required this.onBankSelected,
  }) : super(key: key);

  @override
  State<BankSelectorModal> createState() => _BankSelectorModalState();
}

class _BankSelectorModalState extends State<BankSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<BankData> _filteredBanks = BanksData.banks;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterBanks);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterBanks() {
    setState(() {
      _filteredBanks = BanksData.searchBanks(_searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text(
                'Selecionar Banco',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Color(0xFF8B8B8B)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Search
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Buscar banco...',
              hintStyle: const TextStyle(color: Color(0xFF8B8B8B)),
              prefixIcon: const Icon(Icons.search, color: Color(0xFF8B8B8B)),
              filled: true,
              fillColor: const Color(0xFF2A2A2A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          
          // Banks list
          Expanded(
            child: ListView.builder(
              itemCount: _filteredBanks.length,
              itemBuilder: (context, index) {
                final bank = _filteredBanks[index];
                final isSelected = widget.selectedBank?.code == bank.code;
                
                return InkWell(
                  onTap: () => widget.onBankSelected(bank),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xFF00C977).withOpacity(0.1) : const Color(0xFF2A2A2A),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? const Color(0xFF00C977) : Colors.transparent,
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
                            Icons.account_balance,
                            color: Color(0xFF00C977),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                bank.shortName,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? const Color(0xFF00C977) : Colors.white,
                                ),
                              ),
                              Text(
                                bank.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF8B8B8B),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          bank.code,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isSelected ? const Color(0xFF00C977) : const Color(0xFF8B8B8B),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
