import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../data/banks_data.dart';
import '../../services/api_service.dart';
// BankSelectorModal is defined in bank_account_screen.dart (same directory)
import 'bank_account_screen.dart' show BankSelectorModal;
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../utils/cpf_formatter.dart';
import '../../utils/cnpj_formatter.dart';
import '../../utils/cep_formatter.dart';

// ─────────────────────────────────────────────
// Tela unificada de configuração financeira
// Consolida: dados bancários, chave PIX,
// endereço, configurações Asaas e parcelamento.
// ─────────────────────────────────────────────
class BankingScreen extends StatefulWidget {
  const BankingScreen({Key? key}) : super(key: key);

  @override
  State<BankingScreen> createState() => _BankingScreenState();
}

class _BankingScreenState extends State<BankingScreen> {
  // ── Estado geral ──────────────────────────────
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isFetchingCep = false;
  bool _hasUnsavedChanges = false;

  // Seção Asaas colapsável
  bool _asaasExpanded = false;

  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  // ── Seção 1: Dados Bancários ──────────────────
  BankData? _selectedBank;
  String _selectedAccountType = 'checking';
  final _agencyController = TextEditingController();
  final _accountNumberController = TextEditingController();
  final _holderNameController = TextEditingController();
  final _holderDocumentController = TextEditingController();

  // ── Seção 2: Chave PIX ────────────────────────
  String _selectedPixKeyType = 'cpf';
  final _pixKeyController = TextEditingController();

  // ── Seção 3: Endereço ─────────────────────────
  final _cepController = TextEditingController();
  final _streetController = TextEditingController();
  final _streetNumberController = TextEditingController();
  final _complementController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();

  // ── Seção 4: Configurações Asaas ─────────────
  DateTime? _birthDate;
  String _selectedCompanyType = 'MEI';
  final _incomeController = TextEditingController();

  static const List<String> _companyTypes = [
    'MEI',
    'ME',
    'EPP',
    'LTDA',
    'SA',
    'Autônomo',
  ];

  // ── Seção 5: Parcelamento ─────────────────────
  bool _acceptsInstallment = true;
  int _maxInstallments = 12;

  // ── Controle de mudanças ──────────────────────
  void _markDirty() {
    if (!_hasUnsavedChanges) {
      _safeSetState(() => _hasUnsavedChanges = true);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _attachListeners();
  }

  void _attachListeners() {
    for (final c in [
      _agencyController,
      _accountNumberController,
      _holderNameController,
      _holderDocumentController,
      _pixKeyController,
      _cepController,
      _streetController,
      _streetNumberController,
      _complementController,
      _neighborhoodController,
      _cityController,
      _stateController,
      _incomeController,
    ]) {
      c.addListener(_markDirty);
    }
  }

  @override
  void dispose() {
    for (final c in [
      _agencyController,
      _accountNumberController,
      _holderNameController,
      _holderDocumentController,
      _pixKeyController,
      _cepController,
      _streetController,
      _streetNumberController,
      _complementController,
      _neighborhoodController,
      _cityController,
      _stateController,
      _incomeController,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  // ── Carregamento ──────────────────────────────
  Future<void> _loadAllData() async {
    _safeSetState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await _apiService.loadToken();

      final results = await Future.wait([
        _apiService.getBankAccount(),
        _apiService.getWorkshopProfile(),
      ]);

      final bankResp = results[0];
      final profileResp = results[1];

      // ── Dados bancários + endereço + PIX ──────
      if (bankResp['success'] == true && bankResp['data'] != null) {
        final d = bankResp['data'] as Map<String, dynamic>;

        final bankCode = d['bank_code']?.toString();
        if (bankCode != null && bankCode.isNotEmpty) {
          _selectedBank = BanksData.getBankByCode(bankCode);
        }

        final accountType = d['account_type']?.toString();
        if (accountType != null && accountType.isNotEmpty) {
          _selectedAccountType = accountType;
        }

        _agencyController.text = d['agency_number'] ?? d['agency'] ?? '';
        _accountNumberController.text =
            d['account_number'] ?? d['account'] ?? '';
        _holderNameController.text = d['account_holder_name'] ?? '';
        _holderDocumentController.text = d['account_holder_document'] ?? '';

        final pixType = d['pix_key_type']?.toString();
        if (pixType != null && pixType.isNotEmpty) {
          _selectedPixKeyType = pixType;
        }
        _pixKeyController.text = d['pix_key'] ?? '';

        _cepController.text = d['bank_cep'] ?? '';
        _streetController.text = d['bank_street'] ?? '';
        _streetNumberController.text = d['bank_number'] ?? '';
        _complementController.text = d['bank_complement'] ?? '';
        _neighborhoodController.text = d['bank_neighborhood'] ?? '';
        _cityController.text = d['bank_city'] ?? '';
        _stateController.text = d['bank_state'] ?? '';

        // ── Campos Asaas extras salvos junto aos dados bancários ──
        final income = d['income_value']?.toString();
        if (income != null && income.isNotEmpty) {
          _incomeController.text = income;
        }
        final companyType = d['company_type']?.toString();
        if (companyType != null && companyType.isNotEmpty) {
          final upper = companyType.toUpperCase();
          _selectedCompanyType = _companyTypes.contains(upper) ? upper : 'MEI';
        }
        final birthStr = d['birth_date']?.toString();
        if (birthStr != null && birthStr.isNotEmpty) {
          _birthDate = DateTime.tryParse(birthStr);
        }
      }

      // ── Parcelamento (perfil da oficina) ──────
      if (profileResp['success'] == true) {
        final w = profileResp['data']?['workshop'] ??
            profileResp['data'] as Map<String, dynamic>?;
        if (w != null) {
          _acceptsInstallment = w['accepts_installment'] ?? true;
          final raw = w['max_installments'];
          if (raw != null) {
            final parsed = raw is int
                ? raw
                : int.tryParse(raw.toString()) ?? 12;
            _maxInstallments = parsed.clamp(1, 24);
          }
        }
      }

      // Resetar flag de mudanças após carregamento
      _safeSetState(() => _hasUnsavedChanges = false);
    } catch (_) {
      // Falha silenciosa — campos ficam em branco
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  // ── Salvar ────────────────────────────────────
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedBank == null) {
      _showSnackbar('Selecione um banco.', isError: true);
      return;
    }

    _safeSetState(() => _isSaving = true);
    try {
      // 1) Dados bancários
      final bankResp = await _apiService.updateBankAccount(
        bankName: _selectedBank!.name,
        bankCode: _selectedBank!.code,
        accountType: _selectedAccountType,
        accountNumber: _accountNumberController.text.trim(),
        agencyNumber: _agencyController.text.trim(),
        accountHolderName: _holderNameController.text.trim(),
        accountHolderDocument: _holderDocumentController.text.trim(),
        pixKey: _pixKeyController.text.trim().isNotEmpty
            ? _pixKeyController.text.trim()
            : null,
        pixKeyType: _selectedPixKeyType,
        cep: _cepController.text.trim(),
        street: _streetController.text.trim(),
        number: _streetNumberController.text.trim(),
        neighborhood: _neighborhoodController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        complement: _complementController.text.trim(),
      );

      if (bankResp['success'] != true) {
        _showSnackbar(
          'Erro ao salvar dados bancários: ${bankResp['error'] ?? 'tente novamente.'}',
          isError: true,
        );
        return;
      }

      // 2) Parcelamento
      final installResp = await _apiService.updateWorkshopProfile({
        'accepts_installment': _acceptsInstallment,
        'max_installments': _maxInstallments,
      });

      if (installResp['success'] != true) {
        _showSnackbar(
          'Dados bancários salvos, mas houve erro ao salvar parcelamento.',
          isWarning: true,
        );
        // Não bloqueia — segue com sucesso parcial
      }

      // 3) Verificação pós-save
      await Future.delayed(const Duration(milliseconds: 800));
      final verify = await _apiService.getBankAccount();
      final verified = verify['success'] == true &&
          (verify['data']?['bank_code']?.toString().isNotEmpty ?? false);

      if (!mounted) return;
      _safeSetState(() => _hasUnsavedChanges = false);

      if (verified) {
        _showSnackbar('Dados financeiros salvos com sucesso!');
      } else {
        _showSnackbar(
          'Salvo, mas a verificação não confirmou todos os campos. Recarregue se necessário.',
          isWarning: true,
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      _showSnackbar('Erro inesperado: $e', isError: true);
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  // ── ViaCEP ────────────────────────────────────
  Future<void> _fetchAddressByCep() async {
    final digits = _cepController.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length != 8) {
      _showSnackbar('Informe um CEP válido com 8 dígitos.', isError: true);
      return;
    }
    _safeSetState(() => _isFetchingCep = true);
    try {
      final resp =
          await http.get(Uri.parse('https://viacep.com.br/ws/$digits/json/'));
      if (resp.statusCode == 200) {
        final data = json.decode(resp.body) as Map<String, dynamic>;
        if (data['erro'] != true) {
          _streetController.text = data['logradouro'] ?? '';
          _neighborhoodController.text = data['bairro'] ?? '';
          _cityController.text = data['localidade'] ?? '';
          _stateController.text = data['uf'] ?? '';
          _complementController.text = data['complemento'] ?? '';
          _showSnackbar('Endereço preenchido automaticamente.');
        } else {
          _showSnackbar('CEP não encontrado.', isWarning: true);
        }
      } else {
        _showSnackbar('Erro ao consultar CEP.', isError: true);
      }
    } catch (_) {
      _showSnackbar('Falha na consulta de CEP.', isError: true);
    } finally {
      _safeSetState(() => _isFetchingCep = false);
    }
  }

  // ── Helpers UI ────────────────────────────────
  void _showSnackbar(
    String message, {
    bool isError = false,
    bool isWarning = false,
  }) {
    if (!mounted) return;
    final color = isError
        ? const Color(0xFFEF4444)
        : isWarning
            ? const Color(0xFFF59E0B)
            : const Color(0xFF00C977);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
          'Você tem alterações não salvas. Deseja sair sem salvar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Sair sem salvar',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ── Build ─────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        final bgColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryColor = ThemeService.getSecondaryTextColor(isDark);

        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, _) async {
            if (didPop) return;
            final canLeave = await _onWillPop();
            if (canLeave && mounted) Navigator.pop(context);
          },
          child: Scaffold(
            backgroundColor: bgColor,
            appBar: AppBar(
              title: const Text('Configurações Financeiras'),
              backgroundColor: isDark
                  ? const Color(0xFF0A0A0A)
                  : const Color(0xFF00C977),
              foregroundColor: Colors.white,
              elevation: 0,
              actions: [
                if (_hasUnsavedChanges && !_isLoading)
                  TextButton(
                    onPressed: _isSaving ? null : _save,
                    child: const Text(
                      'Salvar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
              ],
            ),
            body: _isLoading
                ? _buildSkeleton(isDark)
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Cabeçalho ────────────────────────────
                          Text(
                            'Dados Financeiros',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure seus dados bancários para receber pagamentos. A MECA arca com 100% das taxas do gateway.',
                            style: TextStyle(
                              fontSize: 14,
                              color: secondaryColor,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 32),

                          // ── Seção 1: Dados Bancários ─────────────
                          _buildSectionCard(
                            isDark: isDark,
                            icon: Icons.account_balance_rounded,
                            title: 'Dados Bancários',
                            children: [
                              _buildFieldLabel('Banco', textColor),
                              const SizedBox(height: 8),
                              _buildBankSelector(isDark, textColor, secondaryColor),
                              const SizedBox(height: 16),

                              _buildFieldLabel('Tipo de Conta', textColor),
                              const SizedBox(height: 8),
                              _buildAccountTypeSelector(isDark),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _agencyController,
                                label: 'Agência',
                                hint: 'Ex.: 0001',
                                keyboardType: TextInputType.number,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Agência é obrigatória' : null,
                              ),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _accountNumberController,
                                label: 'Número da Conta',
                                hint: 'Ex.: 12345-6',
                                keyboardType: TextInputType.text,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Número da conta é obrigatório' : null,
                              ),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _holderNameController,
                                label: 'Titular',
                                hint: 'Nome completo do titular',
                                textCapitalization: TextCapitalization.words,
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'Nome do titular é obrigatório' : null,
                              ),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _holderDocumentController,
                                label: 'CPF/CNPJ do Titular',
                                hint: 'CPF ou CNPJ',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  TextInputFormatter.withFunction(
                                    (oldValue, newValue) {
                                      final digits = newValue.text
                                          .replaceAll(RegExp(r'\D'), '');
                                      return digits.length <= 11
                                          ? CpfFormatter()
                                              .formatEditUpdate(oldValue, newValue)
                                          : CnpjFormatter()
                                              .formatEditUpdate(oldValue, newValue);
                                    },
                                  ),
                                ],
                                validator: (v) =>
                                    (v == null || v.isEmpty) ? 'CPF/CNPJ é obrigatório' : null,
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Seção 2: Chave PIX ────────────────────
                          _buildSectionCard(
                            isDark: isDark,
                            icon: Icons.pix_rounded,
                            title: 'Chave PIX',
                            children: [
                              _buildFieldLabel('Tipo de Chave', textColor),
                              const SizedBox(height: 10),
                              _buildPixTypeSelector(isDark),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _pixKeyController,
                                label: 'Valor da Chave',
                                hint: _pixKeyHint(),
                                keyboardType: _pixKeyboardType(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Seção 3: Endereço ──────────────────────
                          _buildSectionCard(
                            isDark: isDark,
                            icon: Icons.location_on_rounded,
                            title: 'Endereço',
                            children: [
                              _buildInputField(
                                isDark: isDark,
                                controller: _cepController,
                                label: 'CEP',
                                hint: '00000-000',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  CepFormatter(),
                                  LengthLimitingTextInputFormatter(9),
                                ],
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'CEP é obrigatório';
                                  if (v.replaceAll(RegExp(r'[^0-9]'), '').length != 8) {
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
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Color(0xFF00C977),
                                          ),
                                        ),
                                      )
                                    : IconButton(
                                        icon: const Icon(
                                          Icons.search_rounded,
                                          color: Color(0xFF00C977),
                                        ),
                                        onPressed: _fetchAddressByCep,
                                        tooltip: 'Buscar CEP',
                                      ),
                              ),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _streetController,
                                label: 'Rua / Avenida',
                                hint: 'Ex.: Rua das Flores',
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  SizedBox(
                                    width: 110,
                                    child: _buildInputField(
                                      isDark: isDark,
                                      controller: _streetNumberController,
                                      label: 'Número',
                                      hint: 'Ex.: 123',
                                      keyboardType: TextInputType.text,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: _buildInputField(
                                      isDark: isDark,
                                      controller: _complementController,
                                      label: 'Complemento',
                                      hint: 'Apto, sala...',
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _neighborhoodController,
                                label: 'Bairro',
                                hint: 'Ex.: Centro',
                                textCapitalization: TextCapitalization.words,
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  Expanded(
                                    child: _buildInputField(
                                      isDark: isDark,
                                      controller: _cityController,
                                      label: 'Cidade',
                                      hint: 'Ex.: São Paulo',
                                      textCapitalization:
                                          TextCapitalization.words,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  SizedBox(
                                    width: 90,
                                    child: _buildInputField(
                                      isDark: isDark,
                                      controller: _stateController,
                                      label: 'UF',
                                      hint: 'SP',
                                      textCapitalization:
                                          TextCapitalization.characters,
                                      inputFormatters: [
                                        LengthLimitingTextInputFormatter(2),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Seção 4: Configurações Asaas ──────────
                          _buildCollapsibleCard(
                            isDark: isDark,
                            icon: Icons.tune_rounded,
                            title: 'Configurações Asaas',
                            subtitle: 'Dados adicionais para subconta de pagamentos',
                            expanded: _asaasExpanded,
                            onToggle: () =>
                                _safeSetState(() => _asaasExpanded = !_asaasExpanded),
                            children: [
                              _buildFieldLabel('Data de Nascimento do Responsável', textColor),
                              const SizedBox(height: 8),
                              _buildDatePickerField(isDark, textColor, secondaryColor),
                              const SizedBox(height: 16),

                              _buildFieldLabel('Tipo de Empresa', textColor),
                              const SizedBox(height: 8),
                              _buildCompanyTypeDropdown(isDark, textColor),
                              const SizedBox(height: 16),

                              _buildInputField(
                                isDark: isDark,
                                controller: _incomeController,
                                label: 'Faturamento Mensal Estimado (R\$)',
                                hint: 'Ex.: 15000.00',
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Seção 5: Parcelamento ─────────────────
                          _buildSectionCard(
                            isDark: isDark,
                            icon: Icons.credit_score_rounded,
                            title: 'Parcelamento',
                            children: [
                              _buildInstallmentSection(isDark, textColor, secondaryColor),
                            ],
                          ),
                          const SizedBox(height: 36),

                          // ── Botão Salvar ──────────────────────────
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isSaving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF00C977),
                                disabledBackgroundColor:
                                    const Color(0xFF00C977).withOpacity(0.5),
                                padding: const EdgeInsets.symmetric(vertical: 17),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Salvar Configurações',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        );
      },
    );
  }

  // ── Seção card com ícone e título ─────────────
  Widget _buildSectionCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCardHeader(isDark, icon, title),
          Divider(color: borderColor, height: 1),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollapsibleCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool expanded,
    required VoidCallback onToggle,
    required List<Widget> children,
  }) {
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final secondaryColor = ThemeService.getSecondaryTextColor(isDark);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00C977).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: const Color(0xFF00C977), size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: ThemeService.getTextColor(isDark),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: secondaryColor,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(bool isDark, IconData icon, String title) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF00C977).withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF00C977), size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: ThemeService.getTextColor(isDark),
            ),
          ),
        ],
      ),
    );
  }

  // ── Seletor de banco ──────────────────────────
  Widget _buildBankSelector(bool isDark, Color textColor, Color secondaryColor) {
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return InkWell(
      onTap: _showBankSelectorModal,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            Icon(
              Icons.account_balance_rounded,
              color: const Color(0xFF00C977),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedBank?.name ?? 'Selecione um banco',
                    style: TextStyle(
                      fontSize: 15,
                      color: _selectedBank != null ? textColor : secondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (_selectedBank != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Código: ${_selectedBank!.code}',
                      style: TextStyle(fontSize: 12, color: secondaryColor),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: secondaryColor),
          ],
        ),
      ),
    );
  }

  void _showBankSelectorModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => BankSelectorModal(
        selectedBank: _selectedBank,
        onBankSelected: (bank) {
          _safeSetState(() {
            _selectedBank = bank;
            _hasUnsavedChanges = true;
          });
          Navigator.pop(ctx);
        },
      ),
    );
  }

  // ── Seletor tipo de conta ─────────────────────
  Widget _buildAccountTypeSelector(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: _buildTypeOption(
            isDark: isDark,
            value: 'checking',
            current: _selectedAccountType,
            label: 'Conta Corrente',
            icon: Icons.account_balance_wallet_rounded,
            onTap: () => _safeSetState(() {
              _selectedAccountType = 'checking';
              _hasUnsavedChanges = true;
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTypeOption(
            isDark: isDark,
            value: 'savings',
            current: _selectedAccountType,
            label: 'Poupança',
            icon: Icons.savings_rounded,
            onTap: () => _safeSetState(() {
              _selectedAccountType = 'savings';
              _hasUnsavedChanges = true;
            }),
          ),
        ),
      ],
    );
  }

  // ── Seletor tipo PIX ──────────────────────────
  Widget _buildPixTypeSelector(bool isDark) {
    const pixOptions = [
      {'value': 'cpf', 'label': 'CPF', 'icon': Icons.person_rounded},
      {'value': 'cnpj', 'label': 'CNPJ', 'icon': Icons.business_rounded},
      {'value': 'email', 'label': 'E-mail', 'icon': Icons.email_rounded},
      {'value': 'phone', 'label': 'Telefone', 'icon': Icons.phone_rounded},
      {'value': 'random', 'label': 'Aleatória', 'icon': Icons.shuffle_rounded},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: pixOptions.map((opt) {
        final value = opt['value'] as String;
        final label = opt['label'] as String;
        final icon = opt['icon'] as IconData;
        final isSelected = _selectedPixKeyType == value;

        return InkWell(
          onTap: () => _safeSetState(() {
            _selectedPixKeyType = value;
            _pixKeyController.clear();
            _hasUnsavedChanges = true;
          }),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF00C977).withOpacity(0.1)
                  : ThemeService.getInputColor(isDark),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF00C977)
                    : ThemeService.getBorderColor(isDark),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: isSelected
                      ? const Color(0xFF00C977)
                      : ThemeService.getSecondaryTextColor(isDark),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? const Color(0xFF00C977)
                        : ThemeService.getSecondaryTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _pixKeyHint() {
    switch (_selectedPixKeyType) {
      case 'cpf':
        return '000.000.000-00';
      case 'cnpj':
        return '00.000.000/0000-00';
      case 'email':
        return 'email@exemplo.com';
      case 'phone':
        return '+55 (11) 99999-9999';
      case 'random':
        return 'Chave aleatória gerada pelo banco';
      default:
        return 'Digite sua chave PIX';
    }
  }

  TextInputType _pixKeyboardType() {
    switch (_selectedPixKeyType) {
      case 'cpf':
      case 'cnpj':
      case 'phone':
        return TextInputType.number;
      case 'email':
        return TextInputType.emailAddress;
      default:
        return TextInputType.text;
    }
  }

  // ── Date picker para nascimento ───────────────
  Widget _buildDatePickerField(
      bool isDark, Color textColor, Color secondaryColor) {
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final display = _birthDate != null
        ? '${_birthDate!.day.toString().padLeft(2, '0')}/${_birthDate!.month.toString().padLeft(2, '0')}/${_birthDate!.year}'
        : 'Selecione a data';

    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: _birthDate ??
              DateTime.now().subtract(const Duration(days: 365 * 25)),
          firstDate: DateTime(1920),
          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
          helpText: 'Data de nascimento',
          cancelText: 'Cancelar',
          confirmText: 'Confirmar',
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: Color(0xFF00C977),
                onPrimary: Colors.white,
                surface: Color(0xFF1A1A1A),
                onSurface: Colors.white,
              ),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          _safeSetState(() {
            _birthDate = picked;
            _hasUnsavedChanges = true;
          });
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: inputColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.calendar_today_rounded,
              color: Color(0xFF00C977),
              size: 18,
            ),
            const SizedBox(width: 12),
            Text(
              display,
              style: TextStyle(
                fontSize: 15,
                color: _birthDate != null ? textColor : secondaryColor,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_drop_down_rounded, color: secondaryColor),
          ],
        ),
      ),
    );
  }

  // ── Dropdown tipo empresa ──────────────────────
  Widget _buildCompanyTypeDropdown(bool isDark, Color textColor) {
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: inputColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: DropdownButton<String>(
        value: _selectedCompanyType,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        dropdownColor: const Color(0xFF1A1A1A),
        style: TextStyle(color: textColor, fontSize: 15),
        onChanged: (val) {
          if (val != null) {
            _safeSetState(() {
              _selectedCompanyType = val;
              _hasUnsavedChanges = true;
            });
          }
        },
        items: _companyTypes
            .map(
              (type) => DropdownMenuItem(
                value: type,
                child: Text(type),
              ),
            )
            .toList(),
      ),
    );
  }

  // ── Seção Parcelamento ────────────────────────
  Widget _buildInstallmentSection(
      bool isDark, Color textColor, Color secondaryColor) {
    final borderColor = ThemeService.getBorderColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Toggle aceitar parcelamento
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Aceitar parcelamento',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Permitir que clientes paguem em parcelas',
                    style: TextStyle(fontSize: 12, color: secondaryColor),
                  ),
                ],
              ),
            ),
            Switch(
              value: _acceptsInstallment,
              onChanged: (val) => _safeSetState(() {
                _acceptsInstallment = val;
                _hasUnsavedChanges = true;
              }),
              activeColor: const Color(0xFF00C977),
            ),
          ],
        ),

        if (_acceptsInstallment) ...[
          const SizedBox(height: 20),
          Divider(color: borderColor, height: 1),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Máximo de parcelas',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_maxInstallments}x',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF00C977),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Slider
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(0xFF00C977),
              inactiveTrackColor: const Color(0xFF333333),
              thumbColor: const Color(0xFF00C977),
              overlayColor: const Color(0xFF00C977).withOpacity(0.15),
              valueIndicatorColor: const Color(0xFF00C977),
              valueIndicatorTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            child: Slider(
              value: _maxInstallments.toDouble(),
              min: 1,
              max: 24,
              divisions: 23,
              label: '${_maxInstallments}x',
              onChanged: (val) => _safeSetState(() {
                _maxInstallments = val.round();
                _hasUnsavedChanges = true;
              }),
            ),
          ),

          const SizedBox(height: 12),

          // Quick-select buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [1, 3, 6, 12, 18, 24].map((n) {
              final isSelected = _maxInstallments == n;
              return InkWell(
                onTap: () => _safeSetState(() {
                  _maxInstallments = n;
                  _hasUnsavedChanges = true;
                }),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF00C977)
                        : ThemeService.getInputColor(isDark),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF00C977)
                          : borderColor,
                    ),
                  ),
                  child: Text(
                    '${n}x',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? Colors.white : secondaryColor,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],

        // Nota sobre taxas
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF00C977).withOpacity(0.06),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: const Color(0xFF00C977).withOpacity(0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: Color(0xFF00C977),
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'A MECA arca com 100% das taxas do gateway. Você recebe o valor do serviço já líquido.',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryColor,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Opção genérica selecionável ───────────────
  Widget _buildTypeOption({
    required bool isDark,
    required String value,
    required String current,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final isSelected = current == value;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF00C977).withOpacity(0.1)
              : ThemeService.getInputColor(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF00C977)
                : ThemeService.getBorderColor(isDark),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF00C977)
                  : ThemeService.getSecondaryTextColor(isDark),
              size: 22,
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF00C977)
                    : ThemeService.getSecondaryTextColor(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ── Input field reutilizável ──────────────────
  Widget _buildInputField({
    required bool isDark,
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
    final inputColor = ThemeService.getInputColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryColor = ThemeService.getSecondaryTextColor(isDark);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildFieldLabel(label, textColor),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          style: TextStyle(color: textColor, fontSize: 15),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: secondaryColor),
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
              borderSide: const BorderSide(color: Color(0xFF00C977), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildFieldLabel(String label, Color textColor) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: textColor,
        letterSpacing: 0.1,
      ),
    );
  }

  // ── Skeleton de loading ───────────────────────
  Widget _buildSkeleton(bool isDark) {
    final shimmerColor = isDark
        ? const Color(0xFF1A1A1A)
        : const Color(0xFFE5E5E5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: List.generate(
          4,
          (i) => Container(
            margin: const EdgeInsets.only(bottom: 20),
            height: i == 0 ? 120 : 160,
            decoration: BoxDecoration(
              color: shimmerColor,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
