import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../services/bank_service.dart';
import '../../services/api_service.dart';
import '../../core/app_colors.dart';
import '../../utils/form_styles.dart';
import '../asaas/identity_verification_screen.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({Key? key}) : super(key: key);

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _bankNameController = TextEditingController();
  final _agenciaController = TextEditingController();
  final _contaController = TextEditingController();
  final BankService _bankService = BankService();
  final ApiService _apiService = ApiService();
  bool _loading = false;
  String _accountType = 'corrente';
  bool _acceptsInstallment = true;
  final _birthDateController = TextEditingController();
  final _incomeValueController = TextEditingController(text: '5000');
  final _mobilePhoneController = TextEditingController();
  String _companyType = 'MEI';
  static const _companyTypes = ['MEI', 'ME', 'EPP', 'LTDA', 'SA', 'Autônomo'];

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final res = await _apiService.getWorkshopProfile();
      if (res['success'] == true && res['data'] != null) {
        final workshop = res['data']['workshop'] ?? res['data'];
        if (mounted) {
          setState(() {
            _acceptsInstallment = workshop['accepts_installment'] ?? true;
            // Prefill phone somente se for celular válido (11 dígitos, 3º = 9).
            final rawPhone = (workshop['phone'] ?? '').toString();
            final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
            if (digits.length == 11 && digits[2] == '9') {
              _mobilePhoneController.text = _formatMobile(digits);
            }
          });
        }
      }
    } catch (_) {}
  }

  String _formatMobile(String digits) {
    if (digits.length != 11) return digits;
    return '(${digits.substring(0, 2)}) ${digits.substring(2, 7)}-${digits.substring(7)}';
  }

  bool _isValidMobile(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.length == 11 && digits[2] == '9';
  }

  Future<void> _saveBankDetails() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    // Obter workshopId do usuário logado
    final workshopId = await _apiService.getWorkshopId();
    if (workshopId == null) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erro: Usuário não autenticado')),
      );
      return;
    }

    String? birthDateFormatted;
    if (_birthDateController.text.isNotEmpty) {
      final parts = _birthDateController.text.split('/');
      if (parts.length == 3) {
        birthDateFormatted = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    }

    final mobileDigits = _mobilePhoneController.text.replaceAll(RegExp(r'\D'), '');

    final result = await _bankService.updateBankDetails(
      workshopId: workshopId,
      bankName: _bankNameController.text,
      agencia: _agenciaController.text,
      conta: _contaController.text,
      accountType: _accountType,
      acceptsInstallment: _acceptsInstallment,
      birthDate: birthDateFormatted,
      companyType: _companyType,
      incomeValue: int.tryParse(_incomeValueController.text) ?? 5000,
      mobilePhone: mobileDigits,
    );

    setState(() => _loading = false);

    if (result['success']) {
      final data = result['data'];
      final asaas = data is Map ? data['asaas'] : null;
      final asaasStatus = asaas is Map ? asaas['asaas_status'] : null;
      String msg = 'Dados bancários salvos com sucesso!';
      if (asaasStatus == 'PENDING') {
        msg = 'Dados salvos! Conta de recebimento em análise (até 2 dias úteis).';
      } else if (asaasStatus == 'ACTIVE') {
        msg = 'Dados salvos! Conta de recebimento ativada com sucesso!';
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.primaryColor,
            duration: const Duration(seconds: 4),
          ),
        );
        if (asaasStatus == 'PENDING') {
          // Oferecer ir para a tela de verificação de identidade
          final goVerify = await showDialog<bool>(
            context: context,
            builder: (ctx) => AlertDialog(
              title: const Text('Verificação de Identidade'),
              content: const Text(
                'Sua conta está em análise. Para acelerar a aprovação, complete a verificação de identidade agora.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Depois'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Verificar Agora'),
                ),
              ],
            ),
          );
          if (goVerify == true && mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const IdentityVerificationScreen()),
            );
            return;
          }
        }
        if (mounted) Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        await _showValidationErrorDialog(
          errorCode: result['errorCode']?.toString(),
          message: (result['error'] ?? 'Erro desconhecido').toString(),
          field: result['field']?.toString(),
        );
      }
    }
  }

  Future<void> _showValidationErrorDialog({
    String? errorCode,
    required String message,
    String? field,
  }) async {
    // Mapa de mensagens amigáveis por errorCode.
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
            'Detalhes técnicos: $message\n\n'
            'Revise os dados e tente novamente. Se o problema persistir, contate o suporte.';
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
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                body,
                style: const TextStyle(fontSize: 14, color: Color(0xFF252940), height: 1.45),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    if (field == 'mobile_phone') {
                      FocusScope.of(context).unfocus();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          'Dados Bancários',
          style: TextStyle(color: Color(0xFF252940), fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Color(0xFF252940)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3EDFA),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, color: Color(0xFF7896D8)),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Text(
                        'Configure sua conta para receber os pagamentos dos serviços',
                        style: TextStyle(color: Colors.grey[800]),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Bank Name
              TextFormField(
                controller: _bankNameController,
                style: FormStyles.inputTextStyle(context),
                cursorColor: AppColors.primaryColor,
                decoration: FormStyles.decorate(
                  context,
                  const InputDecoration(
                  labelText: 'Nome do Banco',
                  hintText: 'Ex: Banco do Brasil, Itaú, Santander',
                    prefixIcon: Icon(Icons.account_balance, color: AppColors.primaryColor),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 15),

              // Account Type
              const Text(
                'Tipo de Conta',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF252940)),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildAccountTypeButton('Corrente', 'corrente'),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: _buildAccountTypeButton('Poupança', 'poupanca'),
                  ),
                ],
              ),
              const SizedBox(height: 15),

              // Agência
              TextFormField(
                controller: _agenciaController,
                style: FormStyles.inputTextStyle(context),
                cursorColor: AppColors.primaryColor,
                decoration: FormStyles.decorate(
                  context,
                  const InputDecoration(
                  labelText: 'Agência',
                  hintText: '0000',
                    prefixIcon: Icon(Icons.business, color: AppColors.primaryColor),
                  ),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 15),

              // Conta
              TextFormField(
                controller: _contaController,
                style: FormStyles.inputTextStyle(context),
                cursorColor: AppColors.primaryColor,
                decoration: FormStyles.decorate(
                  context,
                  const InputDecoration(
                  labelText: 'Número da Conta',
                  hintText: '00000-0',
                    prefixIcon: Icon(Icons.credit_card, color: AppColors.primaryColor),
                  ),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Campo obrigatório' : null,
              ),
              const SizedBox(height: 30),

              // Checkbox para aceitar parcelamento
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: const Color(0xFF00C977).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.credit_card,
                          color: Color(0xFF00C977),
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Configurações de Pagamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C977),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptsInstallment,
                          onChanged: (value) {
                            setState(() {
                              _acceptsInstallment = value ?? false;
                            });
                          },
                          activeColor: const Color(0xFF00C977),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Aceito parcelamento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF252940),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Permitir que clientes paguem em parcelas',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: Colors.blue,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'MECA gerencia automaticamente as configurações de parcelamento. Você receberá o valor total do serviço. Para definir o máximo de parcelas, use Perfil → Parcelamento.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue[800],
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
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: const Color(0xFF00C977).withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_outline, color: Color(0xFF00C977), size: 22),
                        SizedBox(width: 10),
                        Text(
                          'Dados do Responsável',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF00C977),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Necessário para ativar a conta de recebimento',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _mobilePhoneController,
                      style: FormStyles.inputTextStyle(context),
                      cursorColor: AppColors.primaryColor,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Celular do responsável *',
                          hintText: '(11) 98765-4321',
                          prefixIcon: Icon(Icons.phone_android, color: AppColors.primaryColor),
                          helperText: 'Somente celular (11 dígitos com DDD). Linhas fixas não são aceitas.',
                          helperMaxLines: 2,
                        ),
                      ),
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
                      },
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Campo obrigatório';
                        if (!_isValidMobile(v)) {
                          return 'Informe um celular válido (DDD + 9 + 8 dígitos)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _birthDateController,
                      style: FormStyles.inputTextStyle(context),
                      cursorColor: AppColors.primaryColor,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Data de nascimento *',
                          hintText: 'dd/mm/aaaa',
                          prefixIcon: Icon(Icons.cake_outlined, color: AppColors.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime(1990, 1, 1),
                          firstDate: DateTime(1940),
                          lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                          locale: const Locale('pt', 'BR'),
                        );
                        if (picked != null && mounted) {
                          setState(() {
                            _birthDateController.text =
                                '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                          });
                        }
                      },
                      validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _companyType,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Tipo de empresa *',
                          prefixIcon: Icon(Icons.business_center_outlined, color: AppColors.primaryColor),
                        ),
                      ),
                      items: _companyTypes.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                      onChanged: (v) => setState(() => _companyType = v ?? 'MEI'),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _incomeValueController,
                      style: FormStyles.inputTextStyle(context),
                      cursorColor: AppColors.primaryColor,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Faturamento mensal estimado (R\$) *',
                          hintText: '5000',
                          prefixIcon: Icon(Icons.attach_money, color: AppColors.primaryColor),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) => (v?.isEmpty ?? true) ? 'Campo obrigatório' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // Save Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _saveBankDetails,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Salvar Dados Bancários',
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
        ),
      ),
    );
  }

  Widget _buildAccountTypeButton(String label, String value) {
    final isSelected = _accountType == value;
    
    return InkWell(
      onTap: () {
        setState(() => _accountType = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryColor : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _agenciaController.dispose();
    _contaController.dispose();
    _birthDateController.dispose();
    _incomeValueController.dispose();
    _mobilePhoneController.dispose();
    super.dispose();
  }
}
