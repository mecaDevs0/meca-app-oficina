import 'dart:async';
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
  bool _isViewMode = false; // true = modo visualização read-only

  // Seção Asaas colapsável
  bool _asaasExpanded = false;
  bool _mobilePhoneHasError = false;

  // ── Estado Asaas ──────────────────────────────
  String? _asaasStatus;
  String? _asaasError;
  bool _isCheckingStatus = false;
  Timer? _pollingTimer;

  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _mobilePhoneFocusNode = FocusNode();
  final _asaasSectionKey = GlobalKey();

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
  final _mobilePhoneController = TextEditingController();

  String _formatMobile(String digits) {
    if (digits.length != 11) return digits;
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }

  bool _isValidMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits[2] == '9';
  }

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
      _mobilePhoneController,
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
      _mobilePhoneController,
    ]) {
      c.dispose();
    }
    _mobilePhoneFocusNode.dispose();
    _pollingTimer?.cancel();
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

        // ── Status Asaas ──
        _asaasStatus = d['asaas_status']?.toString();
        _asaasError = d['asaas_error']?.toString();
        // Pre-fill Asaas fields from DB
        if (d['asaas_birth_date'] != null) {
          try { _birthDate = DateTime.parse(d['asaas_birth_date'].toString()); } catch (_) {}
        }
        if (d['asaas_company_type'] != null) {
          _selectedCompanyType = d['asaas_company_type'].toString();
        }
        if (d['asaas_income_value'] != null) {
          final val = double.tryParse(d['asaas_income_value'].toString());
          if (val != null) _incomeController.text = val.toStringAsFixed(0);
        }
        // Start polling if PENDING
        if (_asaasStatus == 'PENDING') _startStatusPolling();
      }

      // ── Parcelamento (perfil da oficina) ──────
      if (profileResp['success'] == true) {
        final w = profileResp['data']?['workshop'] ??
            profileResp['data'] as Map<String, dynamic>?;
        if (w != null) {
          // Prefill celular se o phone cadastrado for um celular válido.
          // Se for fixo, campo fica vazio e expandimos a seção Asaas para o usuário preencher.
          final rawPhone = (w['phone'] ?? '').toString();
          final phoneDigits = rawPhone.replaceAll(RegExp(r'\D'), '');
          if (phoneDigits.length == 11 && phoneDigits[2] == '9') {
            _mobilePhoneController.text = _formatMobile(phoneDigits);
          } else if (phoneDigits.isNotEmpty) {
            // Telefone cadastrado é fixo — expandir seção Asaas para correção
            _asaasExpanded = true;
          }
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

      // Determinar modo: view (dados existem E subconta Asaas ok) ou edit (falta algo)
      final hasBankData = _selectedBank != null &&
          _agencyController.text.trim().isNotEmpty &&
          _accountNumberController.text.trim().isNotEmpty;
      // Se falta birth_date, forçar modo edição para o usuário preencher
      _isViewMode = hasBankData && _birthDate != null;

      // Resetar flag de mudanças após carregamento
      _safeSetState(() => _hasUnsavedChanges = false);

      // Se o celular está vazio/inválido, marcar campo com erro visual
      if (!_isValidMobile(_mobilePhoneController.text)) {
        _mobilePhoneHasError = true;
      }
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

    if (_birthDate == null) {
      _showSnackbar('Data de nascimento é obrigatória para ativar recebimentos.', isError: true);
      return;
    }

    // Validação local de celular antes de enviar pra API.
    if (!_isValidMobile(_mobilePhoneController.text)) {
      await _showValidationErrorDialog(
        errorCode: 'INVALID_MOBILE_PHONE',
        message: 'Informe um celular válido (DDD + 9 + 8 dígitos).',
        field: 'mobile_phone',
      );
      return;
    }

    _safeSetState(() => _isSaving = true);
    try {
      final mobileDigits = _mobilePhoneController.text.replaceAll(RegExp(r'\D'), '');
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
        birthDate: _birthDate != null
            ? '${_birthDate!.year}-${_birthDate!.month.toString().padLeft(2, '0')}-${_birthDate!.day.toString().padLeft(2, '0')}'
            : null,
        companyType: _selectedCompanyType,
        incomeValue: int.tryParse(_incomeController.text.replaceAll(RegExp(r'[^0-9]'), '')),
        mobilePhone: mobileDigits,
      );

      if (bankResp['success'] != true) {
        // Dialog rico baseado em errorCode estruturado do backend.
        await _showValidationErrorDialog(
          errorCode: bankResp['errorCode']?.toString(),
          message: (bankResp['error'] ?? 'Tente novamente.').toString(),
          field: bankResp['field']?.toString(),
        );
        return;
      }

      // 1b) Resultado Asaas
      final asaasResult = bankResp['asaas'];
      if (asaasResult != null) {
        setState(() {
          _asaasStatus = asaasResult['asaas_status']?.toString();
          _asaasError = asaasResult['error']?.toString();
        });
        if (_asaasStatus == 'PENDING') _startStatusPolling();
        final isAsaasError = _asaasStatus == 'ERROR' || _asaasStatus == 'REJECTED';
        final msg = asaasResult['message']?.toString();
        if (msg != null && msg.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                isAsaasError
                    ? 'Dados bancários salvos, mas houve um erro ao ativar recebimentos. Tente salvar novamente em alguns minutos.'
                    : msg,
              ),
              backgroundColor: isAsaasError ? Colors.red : const Color(0xFF00C977),
              duration: isAsaasError ? const Duration(seconds: 6) : const Duration(seconds: 4),
            ),
          );
        }
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
      await _showValidationErrorDialog(
        errorCode: null,
        message: 'Erro inesperado: $e',
      );
    } finally {
      _safeSetState(() => _isSaving = false);
    }
  }

  Future<void> _showValidationErrorDialog({
    String? errorCode,
    required String message,
    String? field,
  }) async {
    String title;
    String body;
    String actionLabel;
    IconData icon;
    Color accent;

    switch (errorCode) {
      case 'INVALID_MOBILE_PHONE':
        title = 'Celular inválido';
        body = 'O número informado não é um celular válido.\n\n'
            'O Asaas (nosso parceiro de pagamentos) aceita apenas celulares com DDD + 9 + 8 dígitos. '
            'Linhas fixas não são aceitas.\n\n'
            'Exemplo correto: (11) 98765-4321';
        actionLabel = 'Corrigir celular';
        icon = Icons.phone_android;
        accent = Colors.orange.shade700;
        break;
      case 'ASAAS_EMAIL_IN_USE_OTHER_WORKSHOP':
        title = 'E-mail já cadastrado';
        body = 'Este e-mail já está vinculado a outra conta de recebimento no Asaas.\n\n'
            'Isso pode acontecer se você já cadastrou a oficina antes com outro usuário, '
            'ou se o e-mail está sendo usado por outra conta.\n\n'
            'Entre em contato com o suporte MECA para resolver.';
        actionLabel = 'Entendi';
        icon = Icons.mark_email_read_outlined;
        accent = Colors.red.shade700;
        break;
      case 'ASAAS_ONBOARDING_FAILED':
        title = 'Falha ao ativar recebimentos';
        body = 'Não foi possível ativar a conta de recebimentos agora.\n\n'
            'Detalhes: $message\n\n'
            'Revise os dados e tente novamente. Se persistir, contate o suporte.';
        actionLabel = 'Revisar dados';
        icon = Icons.error_outline;
        accent = Colors.red.shade700;
        break;
      default:
        title = 'Erro ao salvar';
        body = message;
        actionLabel = 'Entendi';
        icon = Icons.warning_amber_rounded;
        accent = Colors.red.shade700;
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: accent, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: accent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(fontSize: 14, height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    // Se é erro de celular, expandir seção Asaas e focar no campo
                    if (errorCode == 'INVALID_MOBILE_PHONE') {
                      _safeSetState(() => _asaasExpanded = true);
                      Future.delayed(const Duration(milliseconds: 350), () {
                        if (mounted) {
                          final keyCtx = _asaasSectionKey.currentContext;
                          if (keyCtx != null) {
                            Scrollable.ensureVisible(keyCtx, duration: const Duration(milliseconds: 300));
                          }
                          _mobilePhoneFocusNode.requestFocus();
                        }
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
                : _isViewMode
                    ? _buildViewBody(isDark, textColor, secondaryColor)
                    : SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Banner status Asaas ───────────────────
                          _buildAsaasStatusBanner(),

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
                                keyboardType: TextInputType.number,
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
                              const SizedBox(height: 16),

                              // Data de nascimento — obrigatória para ativar recebimentos via Asaas
                              _buildFieldLabel('Data de Nascimento do Responsável *', textColor),
                              const SizedBox(height: 8),
                              _buildDatePickerField(isDark, textColor, secondaryColor),
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
                            key: _asaasSectionKey,
                            isDark: isDark,
                            icon: Icons.tune_rounded,
                            title: 'Configurações Asaas',
                            subtitle: 'Dados adicionais para subconta de pagamentos',
                            expanded: _asaasExpanded,
                            onToggle: () =>
                                _safeSetState(() => _asaasExpanded = !_asaasExpanded),
                            children: [
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
                              const SizedBox(height: 16),
                              // Banner de alerta quando celular é inválido
                              if (_mobilePhoneHasError)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.shade900.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.orange.shade700, width: 1.5),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700, size: 22),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'O número cadastrado é fixo ou inválido. Informe um celular válido abaixo para ativar recebimentos.',
                                          style: TextStyle(fontSize: 13, color: Colors.orange.shade300, height: 1.3),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              _buildInputField(
                                isDark: isDark,
                                controller: _mobilePhoneController,
                                focusNode: _mobilePhoneFocusNode,
                                label: 'Celular do Responsável',
                                hint: '(11) 98765-4321',
                                keyboardType: TextInputType.phone,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                  LengthLimitingTextInputFormatter(11),
                                ],
                                onChanged: (value) {
                                  final digits = value.replaceAll(RegExp(r'\D'), '');
                                  if (digits.length == 11) {
                                    final formatted = _formatMobile(digits);
                                    if (formatted != value) {
                                      _mobilePhoneController.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(offset: formatted.length),
                                      );
                                    }
                                  }
                                  // Limpar o banner de erro quando o usuário digitar um celular válido
                                  final newValid = _isValidMobile(value);
                                  if (newValid && _mobilePhoneHasError) {
                                    _safeSetState(() => _mobilePhoneHasError = false);
                                  }
                                  _markDirty();
                                },
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Campo obrigatório — necessário para recebimentos';
                                  if (!_isValidMobile(v)) {
                                    return 'Celular inválido — use DDD + 9 + 8 dígitos';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Somente celular (11 dígitos). Linhas fixas não são aceitas pelo Asaas.',
                                style: TextStyle(fontSize: 12, color: secondaryColor),
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

  // ── Polling Asaas ─────────────────────────────
  void _startStatusPolling() {
    _pollingTimer?.cancel();
    int attempts = 0;
    _pollingTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      attempts++;
      if (attempts > 10) { timer.cancel(); return; }
      await _checkAsaasStatus();
    });
  }

  Future<void> _checkAsaasStatus() async {
    if (_isCheckingStatus) return;
    setState(() => _isCheckingStatus = true);
    try {
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      final response = await _apiService.getAsaasStatus(workshopId, force: true);
      if (response['success'] == true && response['data'] != null) {
        final data = response['data'];
        final newStatus = data['asaas_status']?.toString();
        if (newStatus != _asaasStatus) {
          setState(() {
            _asaasStatus = newStatus;
            _asaasError = data['asaas_error']?.toString();
          });
          if (newStatus == 'APPROVED' || newStatus == 'ACTIVE') {
            _pollingTimer?.cancel();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Conta Asaas aprovada! Pronta para receber pagamentos.'),
                  backgroundColor: Color(0xFF00C977),
                ),
              );
            }
          } else if (newStatus == 'REJECTED') {
            _pollingTimer?.cancel();
          }
        }
      }
    } catch (_) {} finally {
      if (mounted) setState(() => _isCheckingStatus = false);
    }
  }

  // ── Helpers de mascaramento ───────────────────
  String _maskAccount(String val) {
    if (val.length <= 4) return val;
    return '${'•' * (val.length - 4)}${val.substring(val.length - 4)}';
  }

  String _maskDocument(String val) {
    final digits = val.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 11) {
      return '•••.•••.${digits.substring(6, 9)}-${digits.substring(9)}';
    }
    if (digits.length == 14) {
      return '••.•••.•••/${digits.substring(8, 12)}-${digits.substring(12)}';
    }
    return val;
  }

  String _maskPixKey(String val, String type) {
    if (type == 'cpf' || type == 'cnpj') return _maskDocument(val);
    if (type == 'email' && val.contains('@')) {
      final parts = val.split('@');
      return '${parts[0].substring(0, 2)}•••@${parts[1]}';
    }
    if (val.length > 6) {
      return '${val.substring(0, 3)}•••${val.substring(val.length - 3)}';
    }
    return val;
  }

  // ── Modo Visualização (Read-Only) ───────────
  Widget _buildViewBody(bool isDark, Color textColor, Color secondaryColor) {
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor = isDark ? Colors.white10 : const Color(0xFFE5E7EB);
    final accountTypeLabel = _selectedAccountType == 'checking' ? 'Corrente' : 'Poupança';

    Widget infoTile(IconData icon, String label, String value, {Color? iconColor}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: (iconColor ?? const Color(0xFF00C977)).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 20, color: iconColor ?? const Color(0xFF00C977)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 12, color: secondaryColor, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(value, style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    Widget sectionCard(String title, IconData titleIcon, List<Widget> children) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
              child: Row(
                children: [
                  Icon(titleIcon, size: 18, color: const Color(0xFF00C977)),
                  const SizedBox(width: 8),
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
                ],
              ),
            ),
            Divider(color: borderColor, height: 1),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Column(children: children),
            ),
          ],
        ),
      );
    }

    // Status badge
    String statusLabel;
    Color statusColor;
    IconData statusIcon;
    if (_asaasStatus == 'APPROVED' || _asaasStatus == 'ACTIVE') {
      statusLabel = 'Conta Ativa';
      statusColor = const Color(0xFF00C977);
      statusIcon = Icons.check_circle;
    } else if (_asaasStatus == 'PENDING') {
      statusLabel = 'Em Análise (1-2 dias úteis)';
      statusColor = const Color(0xFFF59E0B);
      statusIcon = Icons.hourglass_top;
    } else if (_asaasStatus == 'REJECTED') {
      statusLabel = 'Rejeitada';
      statusColor = const Color(0xFFEF4444);
      statusIcon = Icons.cancel;
    } else {
      statusLabel = 'Pendente de Configuração';
      statusColor = const Color(0xFF6B7280);
      statusIcon = Icons.info_outline;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Text('Dados Financeiros', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: textColor, letterSpacing: -0.5)),
          const SizedBox(height: 8),
          Text('Seus dados bancários para recebimento de pagamentos.', style: TextStyle(fontSize: 14, color: secondaryColor, height: 1.4)),
          const SizedBox(height: 24),

          // Status Asaas
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: statusColor.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(statusLabel, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: statusColor)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Banco
          sectionCard('Conta Bancária', Icons.account_balance_rounded, [
            infoTile(Icons.business, 'Banco', _selectedBank != null ? '${_selectedBank!.name} (${_selectedBank!.code})' : 'Não informado'),
            infoTile(Icons.credit_card, 'Tipo', accountTypeLabel),
            infoTile(Icons.tag, 'Agência', _agencyController.text.isNotEmpty ? _agencyController.text : '—'),
            infoTile(Icons.numbers, 'Conta', _accountNumberController.text.isNotEmpty ? _maskAccount(_accountNumberController.text) : '—'),
          ]),

          // Titular
          sectionCard('Titular', Icons.person_rounded, [
            infoTile(Icons.badge, 'Nome', _holderNameController.text.isNotEmpty ? _holderNameController.text : '—'),
            infoTile(Icons.fingerprint, 'Documento', _holderDocumentController.text.isNotEmpty ? _maskDocument(_holderDocumentController.text) : '—'),
          ]),

          // PIX
          if (_pixKeyController.text.isNotEmpty)
            sectionCard('Chave PIX', Icons.pix_rounded, [
              infoTile(Icons.vpn_key, _selectedPixKeyType.toUpperCase(), _maskPixKey(_pixKeyController.text, _selectedPixKeyType)),
            ]),

          // Parcelamento
          sectionCard('Parcelamento', Icons.calendar_month_rounded, [
            infoTile(
              _acceptsInstallment ? Icons.check_circle : Icons.cancel,
              'Aceita Parcelamento',
              _acceptsInstallment ? 'Sim — até ${_maxInstallments}x' : 'Não',
              iconColor: _acceptsInstallment ? const Color(0xFF00C977) : const Color(0xFFEF4444),
            ),
          ]),

          const SizedBox(height: 32),

          // Botão Editar
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton.icon(
              onPressed: () => _safeSetState(() => _isViewMode = false),
              icon: const Icon(Icons.edit, size: 20),
              label: const Text('Editar Dados Bancários', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00C977),
                side: const BorderSide(color: Color(0xFF00C977), width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── Banner de status Asaas ────────────────────
  Widget _buildAsaasStatusBanner() {
    Color bgColor;
    IconData icon;
    String title;
    String subtitle;

    switch (_asaasStatus) {
      case 'APPROVED':
      case 'ACTIVE':
        bgColor = const Color(0xFF00C977);
        icon = Icons.check_circle;
        title = 'Conta Asaas Ativa';
        subtitle = 'Pronta para receber pagamentos';
      case 'PENDING':
        bgColor = Colors.orange;
        icon = Icons.hourglass_top;
        title = 'Em Analise pelo Asaas';
        subtitle = 'Aguardando aprovacao (1-2 dias uteis)';
      case 'REJECTED':
        bgColor = Colors.red;
        icon = Icons.error;
        title = 'Documentos Rejeitados';
        subtitle = _asaasError ?? 'Verifique seus dados e salve novamente';
      case 'ERROR':
        bgColor = Colors.red.shade700;
        icon = Icons.warning;
        title = 'Erro no Cadastro';
        subtitle = _asaasError ?? 'Tente salvar novamente';
      case 'DISABLED':
        bgColor = Colors.grey;
        icon = Icons.block;
        title = 'Conta Desativada';
        subtitle = 'Entre em contato com o suporte';
      default:
        bgColor = Colors.grey;
        icon = Icons.account_balance_wallet_outlined;
        title = 'Configure sua Conta';
        subtitle = 'Preencha os dados para ativar recebimentos';
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bgColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: bgColor, size: 32),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: bgColor, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: bgColor.withOpacity(0.8), fontSize: 13)),
              ],
            ),
          ),
          if (_asaasStatus == 'PENDING')
            _isCheckingStatus
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : IconButton(icon: const Icon(Icons.refresh, color: Colors.orange), onPressed: _checkAsaasStatus, tooltip: 'Verificar status'),
        ],
      ),
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
    Key? key,
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
      key: key,
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
      child: Theme(
        data: Theme.of(context).copyWith(
          canvasColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        ),
        child: DropdownButton<String>(
          value: _selectedCompanyType,
          isExpanded: true,
          underline: const SizedBox.shrink(),
          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          iconEnabledColor: textColor.withValues(alpha: 0.6),
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
                  child: Text(type, style: TextStyle(color: textColor)),
                ),
              )
              .toList(),
        ),
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
    void Function(String)? onChanged,
    FocusNode? focusNode,
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
          focusNode: focusNode,
          keyboardType: keyboardType,
          validator: validator,
          readOnly: readOnly,
          textCapitalization: textCapitalization,
          inputFormatters: inputFormatters,
          onChanged: onChanged,
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
