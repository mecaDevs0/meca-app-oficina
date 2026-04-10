import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/app_colors.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';

/// Tela de Verificação de Identidade Asaas — wizard multi-step.
///
/// Fluxo: overview status → pendências → ação (link externo ou upload) → sucesso.
class IdentityVerificationScreen extends StatefulWidget {
  const IdentityVerificationScreen({Key? key}) : super(key: key);

  @override
  State<IdentityVerificationScreen> createState() =>
      _IdentityVerificationScreenState();
}

class _IdentityVerificationScreenState
    extends State<IdentityVerificationScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;

  // Dados da API
  Map<String, dynamic> _approval = {};
  List<Map<String, dynamic>> _documentGroups = [];
  String? _asaasStatus;
  String? _rootOnboardingUrl;
  String? _onboardingUrlStatus;
  List<dynamic>? _rejectReasons;

  bool _resendingLink = false;
  Timer? _pollTimer;
  bool _isAppInForeground = true;

  // Upload state
  final Map<String, bool> _uploading = {};
  final Map<String, String> _uploadMessages = {};

  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _pollTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isAppInForeground = state == AppLifecycleState.resumed;
    if (state == AppLifecycleState.resumed) {
      _loadData(silent: true);
      _maybeStartPolling();
    } else {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadData({bool silent = false}) async {
    final previousGeneral = _approval['general']?.toString().toUpperCase();

    if (!silent) {
      _safeSetState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final res = await _apiService.getAsaasDocuments();

      if (res['success'] == true && res['data'] != null) {
        final data = Map<String, dynamic>.from(res['data'] as Map);
        final newApproval =
            Map<String, dynamic>.from((data['approval'] as Map?) ?? {});
        final newGeneral = newApproval['general']?.toString().toUpperCase();

        _safeSetState(() {
          _approval = newApproval;
          _asaasStatus = data['asaas_status']?.toString();
          _rootOnboardingUrl = data['onboarding_url']?.toString();
          _onboardingUrlStatus = data['onboarding_url_status']?.toString();
          _rejectReasons = data['reject_reasons'] as List?;

          final rawGroups = data['document_groups'];
          if (rawGroups is List) {
            _documentGroups = rawGroups
                .map((e) => Map<String, dynamic>.from(e as Map))
                .toList();
          } else {
            _documentGroups = [];
          }
        });

        if (previousGeneral != 'APPROVED' && newGeneral == 'APPROVED') {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text(
                    '🎉 Verificação aprovada! Você já pode receber pagamentos.'),
                backgroundColor: AppColors.primaryColor,
                duration: const Duration(seconds: 4),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            );
            HapticFeedback.heavyImpact();
          }
          _pollTimer?.cancel();
          _pollTimer = null;
        }
      } else {
        if (!silent) {
          _safeSetState(() {
            _errorMessage = res['error']?.toString() ??
                'Erro ao carregar dados de verificação.';
          });
        }
      }
    } catch (e) {
      if (!silent) {
        _safeSetState(
            () => _errorMessage = 'Erro de conexão: ${e.toString()}');
      }
    } finally {
      if (!silent) {
        _safeSetState(() => _isLoading = false);
      }
      _maybeStartPolling();
    }
  }

  void _maybeStartPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;

    if (!_isAppInForeground) return;
    if (_allApproved) return;

    final hasPending = _documentGroups.any((g) {
      final s = (g['status'] ?? '').toString().toUpperCase();
      return s == 'PENDING' ||
          s == 'AWAITING_APPROVAL' ||
          s == 'NOT_SENT';
    });
    final docPending =
        (_approval['documentation'] ?? '').toString().toUpperCase() !=
            'APPROVED';

    if (!hasPending && !docPending) return;

    _pollTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (!mounted || !_isAppInForeground) {
        _pollTimer?.cancel();
        return;
      }
      _loadData(silent: true);
    });
  }

  // ── Helpers ──────────────────────────────────────

  bool get _allApproved {
    final general = _approval['general']?.toString().toUpperCase();
    return general == 'APPROVED';
  }

  int get _completedSteps {
    int count = 0;
    if (_statusIsGood(_approval['commercialInfo'])) count++;
    if (_statusIsGood(_approval['bankAccountInfo'])) count++;
    if (_statusIsGood(_approval['documentation'])) count++;
    return count;
  }

  bool _statusIsGood(dynamic status) {
    if (status == null) return false;
    final s = status.toString().toUpperCase();
    return s == 'APPROVED' || s == 'PENDING' || s == 'AWAITING_APPROVAL';
  }

  String _statusLabel(dynamic status) {
    if (status == null) return 'Pendente';
    switch (status.toString().toUpperCase()) {
      case 'APPROVED':
        return 'Aprovado';
      case 'PENDING':
      case 'AWAITING_APPROVAL':
        return 'Em análise';
      case 'REJECTED':
        return 'Rejeitado';
      case 'NOT_SENT':
        return 'Não enviado';
      default:
        return status.toString();
    }
  }

  Color _statusColor(dynamic status) {
    if (status == null) return AppColors.fontLightGrayColor;
    switch (status.toString().toUpperCase()) {
      case 'APPROVED':
        return AppColors.primaryColor;
      case 'PENDING':
      case 'AWAITING_APPROVAL':
        return AppColors.yellowWarningColor;
      case 'REJECTED':
        return AppColors.redAlertColor;
      default:
        return AppColors.fontLightGrayColor;
    }
  }

  IconData _statusIcon(dynamic status) {
    if (status == null) return Icons.radio_button_unchecked;
    switch (status.toString().toUpperCase()) {
      case 'APPROVED':
        return Icons.check_circle;
      case 'PENDING':
      case 'AWAITING_APPROVAL':
        return Icons.hourglass_top;
      case 'REJECTED':
        return Icons.cancel;
      default:
        return Icons.radio_button_unchecked;
    }
  }

  /// Mesma regra da API: KYC (RG, selfie, contratos) só pelo fluxo web Asaas, não por multipart.
  bool _docRequiresExternalFlow(Map<String, dynamic> group) {
    if (group['requiresExternalLink'] == true) return true;
    final desc = (group['description']?.toString() ?? '').toLowerCase();
    if (desc.contains('acesse nosso aplicativo') ||
        desc.contains('utilize o link') ||
        desc.contains('aplicativo ou utilize') ||
        desc.contains('neste link') ||
        desc.contains('link de verifica') ||
        desc.contains('cadastro.io')) {
      return true;
    }
    final type = (group['type']?.toString() ?? '').toUpperCase().trim();
    const blocked = {
      'IDENTIFICATION',
      'IDENTIFICATION_SELFIE',
      'SELFIE',
      'ENTREPRENEUR_REQUIREMENT',
      'SOCIAL_CONTRACT',
      'MEI_CERTIFICATE',
      'MINUTES_OF_CONSTITUTION',
      'MINUTES_OF_ELECTION',
      'POWER_OF_ATTORNEY',
    };
    return blocked.contains(type);
  }

  /// Alinha com AccountDocumentSaveRequestAccountDocumentType (Asaas v3).
  String _normalizeAsaasUploadType(String type) {
    final t = type.toUpperCase().trim();
    if (t.isEmpty || t == 'UNKNOWN') return 'IDENTIFICATION';
    const map = {
      'SELFIE': 'IDENTIFICATION_SELFIE',
      'SELFIE_IDENTIFICACAO': 'IDENTIFICATION_SELFIE',
      'ID_SELFIE': 'IDENTIFICATION_SELFIE',
    };
    return map[t] ?? t;
  }

  String _docTypeLabel(String type) {
    switch (type.toUpperCase()) {
      case 'IDENTIFICATION':
        return 'Documento de Identidade';
      case 'IDENTIFICATION_SELFIE':
      case 'SELFIE':
        return 'Selfie com Documento';
      case 'ENTREPRENEUR_REQUIREMENT':
        return 'Comprovante MEI / Empresa';
      case 'SOCIAL_CONTRACT':
        return 'Contrato Social';
      case 'CUSTOM':
        return 'Documento Personalizado';
      default:
        return type;
    }
  }

  IconData _docTypeIcon(String type) {
    switch (type.toUpperCase()) {
      case 'IDENTIFICATION':
        return Icons.badge_outlined;
      case 'IDENTIFICATION_SELFIE':
      case 'SELFIE':
        return Icons.face_retouching_natural;
      case 'ENTREPRENEUR_REQUIREMENT':
        return Icons.business_center_outlined;
      case 'SOCIAL_CONTRACT':
        return Icons.description_outlined;
      default:
        return Icons.insert_drive_file_outlined;
    }
  }

  // ── Actions ──────────────────────────────────────

  Future<void> _openExternalLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Não foi possível abrir o link de verificação.', isError: true);
    }
  }

  Future<void> _pickAndUploadDocument(Map<String, dynamic> group) async {
    if (_docRequiresExternalFlow(group)) {
      _showSnack(
        'Este documento deve ser enviado pelo link do Asaas (verificação web), não por upload aqui.',
        isError: true,
      );
      return;
    }

    final groupId = group['id'].toString();

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildPickerSheet(ctx),
    );
    if (source == null) return;

    final picker = ImagePicker();
    // Redimensionar/comprimir para JPEG leve (evita HEIC e 400 do Asaas por formato/tamanho).
    final picked = await picker.pickImage(
      source: source,
      imageQuality: 72,
      maxWidth: 1600,
      maxHeight: 1600,
    );
    if (picked == null) return;

    _safeSetState(() {
      _uploading[groupId] = true;
      _uploadMessages.remove(groupId);
    });

    try {
      final file = File(picked.path);
      final rawType = group['type']?.toString() ?? 'IDENTIFICATION';
      final docType = _normalizeAsaasUploadType(rawType);
      final res = await _apiService.uploadAsaasDocument(groupId, file, type: docType);

      if (res['success'] == true) {
        _safeSetState(() {
          _uploadMessages[groupId] = res['message']?.toString() ??
              'Documento enviado! Análise em até 48h.';
        });
        // Recarregar status após upload
        await Future.delayed(const Duration(seconds: 1));
        await _loadData();
      } else {
        _safeSetState(() {
          _uploadMessages[groupId] =
              '❌ ${res['error'] ?? 'Erro ao enviar documento'}';
        });
      }
    } catch (e) {
      _safeSetState(() {
        _uploadMessages[groupId] = '❌ Erro: ${e.toString()}';
      });
    } finally {
      _safeSetState(() => _uploading[groupId] = false);
    }
  }

  Future<void> _resendLink() async {
    if (_resendingLink) return;
    _safeSetState(() => _resendingLink = true);

    try {
      final res = await _apiService.resendAsaasOnboardingLink();
      if (res['success'] == true) {
        final newUrl = res['new_url']?.toString();
        if (newUrl != null && newUrl.isNotEmpty) {
          _showSnack('Novo link gerado! Abrindo...');
          await _openExternalLink(newUrl);
        } else {
          _showSnack(res['message']?.toString() ??
              'Solicitação enviada. Verifique o e-mail Asaas em alguns minutos.');
        }
        await _loadData(silent: true);
      } else {
        _showSnack(
          res['error']?.toString() ?? 'Falha ao reenviar link',
          isError: true,
        );
      }
    } catch (e) {
      _showSnack('Erro: ${e.toString()}', isError: true);
    } finally {
      _safeSetState(() => _resendingLink = false);
    }
  }

  Future<void> _showCommercialInfoEditor() async {
    final cpfController = TextEditingController();
    final phoneController = TextEditingController();
    final cepController = TextEditingController();
    final addressController = TextEditingController();
    final numberController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer<ThemeService>(
        builder: (_, themeService, __) {
          final isDark = themeService.isDarkMode;
          final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
          final textColor = isDark ? Colors.white : AppColors.blackPrimaryColor;

          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white24 : AppColors.grayMedium,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Corrigir Dados Comerciais',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Preencha apenas os campos que deseja corrigir. Os demais serão mantidos.',
                      style: TextStyle(
                        color: isDark ? Colors.white60 : AppColors.fontDarkGrayColor,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildSheetField('CPF/CNPJ', cpfController, textColor, isDark,
                        keyboardType: TextInputType.number),
                    _buildSheetField('Telefone', phoneController, textColor, isDark,
                        keyboardType: TextInputType.phone),
                    _buildSheetField('CEP', cepController, textColor, isDark,
                        keyboardType: TextInputType.number),
                    _buildSheetField('Endereço', addressController, textColor, isDark),
                    _buildSheetField('Número', numberController, textColor, isDark,
                        keyboardType: TextInputType.number),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final payload = <String, dynamic>{};
                          if (cpfController.text.trim().isNotEmpty) {
                            payload['cpfCnpj'] = cpfController.text.trim();
                          }
                          if (phoneController.text.trim().isNotEmpty) {
                            payload['mobilePhone'] = phoneController.text.trim();
                          }
                          if (cepController.text.trim().isNotEmpty) {
                            payload['postalCode'] = cepController.text.trim();
                          }
                          if (addressController.text.trim().isNotEmpty) {
                            payload['address'] = addressController.text.trim();
                          }
                          if (numberController.text.trim().isNotEmpty) {
                            payload['addressNumber'] = numberController.text.trim();
                          }
                          Navigator.pop(ctx, payload);
                        },
                        child: const Text(
                          'Enviar correção',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );

    if (result == null || result.isEmpty) return;

    _safeSetState(() => _isLoading = true);
    try {
      final res = await _apiService.updateAsaasCommercialInfo(result);
      if (res['success'] == true) {
        _showSnack(res['message']?.toString() ??
            'Dados atualizados! Novo ciclo de análise iniciado.');
        await _loadData();
      } else {
        _showSnack(res['error']?.toString() ?? 'Erro ao atualizar dados',
            isError: true);
      }
    } catch (e) {
      _showSnack('Erro: ${e.toString()}', isError: true);
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Widget _buildSheetField(
      String label, TextEditingController controller, Color textColor, bool isDark,
      {TextInputType keyboardType = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: isDark ? Colors.white54 : AppColors.fontDarkGrayColor,
            fontSize: 14,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(
              color: isDark ? Colors.white12 : AppColors.grayBorderColor,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: AppColors.primaryColor),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Future<void> _openSupportWhatsApp() async {
    const supportNumber = '551130644243';
    final uri = Uri.parse(
        'https://wa.me/$supportNumber?text=Preciso%20de%20ajuda%20com%20a%20verificação%20Asaas');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      _showSnack('Não foi possível abrir o WhatsApp.', isError: true);
    }
  }

  Widget _buildExternalLinkCta(Map<String, dynamic> group) {
    final url = group['onboardingUrl']?.toString();

    if (url != null && url.isNotEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.open_in_new),
            label: const Text(
              'Abrir verificação Asaas',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            onPressed: () => _openExternalLink(url),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_onboardingUrlStatus == 'regenerating')
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Gerando link no Asaas… tente reenviar em instantes ou atualize a tela.',
              style: TextStyle(
                color: AppColors.yellowWarningColor,
                fontSize: 12,
              ),
            ),
          ),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primaryColor,
            side: const BorderSide(color: AppColors.primaryColor),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: _resendingLink
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.email_outlined),
          label: Text(_resendingLink ? 'Enviando...' : 'Reenviar link por e-mail'),
          onPressed: _resendingLink ? null : _resendLink,
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          icon: const Icon(Icons.support_agent),
          label: const Text('Falar com suporte MECA'),
          onPressed: _openSupportWhatsApp,
        ),
      ],
    );
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.redAlertColor : AppColors.primaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Build ──────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0A0A0A) : AppColors.bgLightGrayColor;
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.blackPrimaryColor;
        final subtextColor =
            isDark ? Colors.white70 : AppColors.fontDarkGrayColor;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Verificação de Identidade',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            centerTitle: true,
            actions: [
              if (!_isLoading)
                IconButton(
                  icon: Icon(Icons.refresh, color: AppColors.primaryColor),
                  onPressed: _loadData,
                  tooltip: 'Atualizar status',
                ),
            ],
          ),
          body: _isLoading
              ? _buildLoadingState(isDark)
              : _errorMessage != null
                  ? _buildErrorState(textColor, subtextColor)
                  : _allApproved
                      ? _buildSuccessState(isDark, textColor, subtextColor)
                      : _buildMainContent(
                          isDark, cardColor, textColor, subtextColor),
        );
      },
    );
  }

  // ── Loading ──────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Carregando verificação...',
            style: TextStyle(
              color: isDark ? Colors.white70 : AppColors.fontDarkGrayColor,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────

  Widget _buildErrorState(Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.redAlertColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline,
                  color: AppColors.redAlertColor, size: 36),
            ),
            const SizedBox(height: 20),
            Text(
              'Não foi possível carregar',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(color: subtextColor, fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Success (all approved) ──────────────────────

  Widget _buildSuccessState(
      bool isDark, Color textColor, Color subtextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _pulseAnimation,
              child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryColor.withOpacity(0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.verified, color: Colors.white, size: 48),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'Conta Verificada!',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Sua conta Asaas foi aprovada com sucesso.\nVocê já pode receber pagamentos normalmente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subtextColor,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: const Text(
                'Voltar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Main Content ──────────────────────────────────

  Widget _buildMainContent(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.primaryColor,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // Header illustration
          _buildHeaderCard(isDark, textColor, subtextColor),
          const SizedBox(height: 20),

          // Progress overview
          _buildProgressSection(isDark, cardColor, textColor, subtextColor),
          const SizedBox(height: 20),

          // Approval steps
          _buildApprovalSteps(isDark, cardColor, textColor, subtextColor),
          const SizedBox(height: 20),

          // Reject reasons (if any)
          if (_rejectReasons != null && _rejectReasons!.isNotEmpty) ...[
            _buildRejectReasons(isDark, cardColor, textColor),
            const SizedBox(height: 20),
          ],

          // Document groups
          if (_documentGroups.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Documentos Pendentes',
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ..._documentGroups.map((g) =>
                _buildDocumentCard(g, isDark, cardColor, textColor, subtextColor)),
          ],

          if (_documentGroups.isEmpty && !_allApproved)
            _buildNoDocsNeeded(isDark, cardColor, textColor, subtextColor),
        ],
      ),
    );
  }

  // ── Header card ──────────────────────────────────

  Widget _buildHeaderCard(
      bool isDark, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1A2A20), const Color(0xFF1A1A1A)]
              : [const Color(0xFFE8FFF3), const Color(0xFFF0FFF7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.primaryColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.shield_outlined,
                color: AppColors.primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ative sua conta',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Complete as etapas abaixo para receber pagamentos via Asaas.',
                  style: TextStyle(
                    color: subtextColor,
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Progress section ──────────────────────────────

  Widget _buildProgressSection(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    final total = 3;
    final completed = _completedSteps;
    final progress = completed / total;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Progresso',
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$completed de $total',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark
                  ? Colors.white.withOpacity(0.08)
                  : AppColors.grayBorderColor,
              valueColor:
                  AlwaysStoppedAnimation<Color>(AppColors.primaryColor),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _asaasStatus == 'APPROVED'
                ? 'Conta aprovada!'
                : completed == total
                    ? 'Tudo enviado — aguardando análise do Asaas.'
                    : 'Complete as etapas pendentes para ativar sua conta.',
            style: TextStyle(color: subtextColor, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ── Approval steps ──────────────────────────────

  Widget _buildApprovalSteps(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    final steps = [
      {
        'key': 'commercialInfo',
        'label': 'Dados Comerciais',
        'desc': 'Informações da oficina (CNPJ, endereço, etc.)',
        'icon': Icons.store_outlined,
      },
      {
        'key': 'bankAccountInfo',
        'label': 'Dados Bancários',
        'desc': 'Conta para recebimento dos pagamentos',
        'icon': Icons.account_balance_outlined,
      },
      {
        'key': 'documentation',
        'label': 'Documentos',
        'desc': 'Identidade e verificação de segurança',
        'icon': Icons.verified_user_outlined,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
            child: Text(
              'Etapas de Verificação',
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ...steps.asMap().entries.map((entry) {
            final i = entry.key;
            final step = entry.value;
            final status = _approval[step['key']];
            final isLast = i == steps.length - 1;

            return _buildStepTile(
              icon: step['icon'] as IconData,
              label: step['label'] as String,
              description: step['desc'] as String,
              status: status,
              isDark: isDark,
              textColor: textColor,
              subtextColor: subtextColor,
              showDivider: !isLast,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStepTile({
    required IconData icon,
    required String label,
    required String description,
    required dynamic status,
    required bool isDark,
    required Color textColor,
    required Color subtextColor,
    bool showDivider = true,
  }) {
    final color = _statusColor(status);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        color: subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_statusIcon(status), color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      _statusLabel(status),
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            indent: 78,
            endIndent: 20,
            color: isDark
                ? Colors.white.withOpacity(0.06)
                : AppColors.grayBorderColor,
          ),
      ],
    );
  }

  // ── Reject reasons ──────────────────────────────

  Widget _buildRejectReasons(
      bool isDark, Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.redAlertColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.redAlertColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: AppColors.redAlertColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Motivos de Rejeição',
                style: TextStyle(
                  color: AppColors.redAlertColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...(_rejectReasons ?? []).map((reason) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline,
                        color: AppColors.redAlertColor, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        reason.toString(),
                        style: TextStyle(color: textColor, fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.redAlertColor,
                side: BorderSide(color: AppColors.redAlertColor.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              icon: const Icon(Icons.edit_outlined, size: 18),
              label: const Text(
                'Corrigir dados comerciais',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              onPressed: _showCommercialInfoEditor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Document cards ──────────────────────────────

  Widget _buildDocumentCard(Map<String, dynamic> group, bool isDark,
      Color cardColor, Color textColor, Color subtextColor) {
    final groupId = group['id'].toString();
    final status = group['status']?.toString() ?? 'NOT_SENT';
    final type = group['type']?.toString() ?? 'UNKNOWN';
    final title = group['title']?.toString() ?? '';
    final description = group['description']?.toString() ?? '';
    final groupOnboardingUrl = group['onboardingUrl']?.toString();
    // Fallback: usar URL raiz da conta quando o grupo não tem URL próprio
    final onboardingUrl = (groupOnboardingUrl != null && groupOnboardingUrl.isNotEmpty)
        ? groupOnboardingUrl
        : _rootOnboardingUrl;
    final requiresExternalLink = _docRequiresExternalFlow(group);
    final isUploading = _uploading[groupId] == true;
    final uploadMsg = _uploadMessages[groupId];

    final statusUpper = status.toUpperCase();
    final isApproved = statusUpper == 'APPROVED';
    final isPending = statusUpper == 'PENDING' || statusUpper == 'AWAITING_APPROVAL';
    final isNotSent = statusUpper == 'NOT_SENT';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApproved
              ? AppColors.primaryColor.withOpacity(0.3)
              : isPending
                  ? AppColors.yellowWarningColor.withOpacity(0.3)
                  : isDark
                      ? Colors.white.withOpacity(0.06)
                      : AppColors.grayBorderColor,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(
                    _docTypeIcon(type),
                    color: _statusColor(status),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title.isNotEmpty ? title : _docTypeLabel(type),
                        style: TextStyle(
                          color: textColor,
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          description,
                          style: TextStyle(
                            color: subtextColor,
                            fontSize: 12,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(
                      color: _statusColor(status),
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Upload message
          if (uploadMsg != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: uploadMsg.startsWith('❌')
                      ? AppColors.redAlertColor.withOpacity(0.1)
                      : AppColors.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  uploadMsg,
                  style: TextStyle(
                    fontSize: 12,
                    color: uploadMsg.startsWith('❌')
                        ? AppColors.redAlertColor
                        : AppColors.primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

          // Action area
          if (isNotSent || statusUpper == 'REJECTED')
            Padding(
              padding: const EdgeInsets.all(16),
              child: requiresExternalLink
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildExternalLinkCta(
                          Map<String, dynamic>.from(group)
                            ..['onboardingUrl'] = onboardingUrl,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.yellowWarningColor.withOpacity(0.08),
                            border: Border.all(
                                color: AppColors.yellowWarningColor
                                    .withOpacity(0.5)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.info_outline,
                                  color: AppColors.yellowWarningColor,
                                  size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'O Asaas não aceita RG/selfie pelo app MECA: use o link acima ou verifique o e-mail enviado pelo Asaas.',
                                  style: TextStyle(
                                    color: AppColors.yellowWarningColor,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : _buildUploadButton(group, isUploading, isDark),
            )
          else if (isPending)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.yellowWarningColor),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Documento em análise pelo Asaas...',
                    style: TextStyle(
                      color: AppColors.yellowWarningColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          else if (isApproved)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  Icon(Icons.check_circle,
                      color: AppColors.primaryColor, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Documento aprovado',
                    style: TextStyle(
                      color: AppColors.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUploadButton(
      Map<String, dynamic> group, bool isUploading, bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: isUploading ? null : () => _pickAndUploadDocument(group),
        icon: isUploading
            ? SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.primaryColor),
                ),
              )
            : Icon(Icons.cloud_upload_outlined,
                size: 18, color: AppColors.primaryColor),
        label: Text(
          isUploading ? 'Enviando...' : 'Enviar Documento',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isUploading
                ? AppColors.fontLightGrayColor
                : AppColors.primaryColor,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: AppColors.primaryColor.withOpacity(0.5)),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // ── No documents needed ──────────────────────────

  Widget _buildNoDocsNeeded(
      bool isDark, Color cardColor, Color textColor, Color subtextColor) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.yellowWarningColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.hourglass_top,
                color: AppColors.yellowWarningColor, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            'Aguardando liberação',
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nenhum documento adicional necessário no momento.\nO Asaas está analisando suas informações.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: subtextColor,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _loadData,
            icon: Icon(Icons.refresh, size: 16, color: AppColors.primaryColor),
            label: Text(
              'Verificar novamente',
              style: TextStyle(
                  color: AppColors.primaryColor, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Picker bottom sheet ──────────────────────────

  Widget _buildPickerSheet(BuildContext ctx) {
    return Consumer<ThemeService>(
      builder: (_, themeService, __) {
        final isDark = themeService.isDarkMode;
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDark ? Colors.white : AppColors.blackPrimaryColor;

        return Container(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.grayMedium,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Selecionar documento',
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 20),
              _buildPickerOption(
                icon: Icons.camera_alt_outlined,
                label: 'Tirar Foto',
                subtitle: 'Use a câmera para capturar o documento',
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
                isDark: isDark,
                textColor: textColor,
              ),
              const SizedBox(height: 12),
              _buildPickerOption(
                icon: Icons.photo_library_outlined,
                label: 'Galeria',
                subtitle: 'Escolha uma imagem salva no dispositivo',
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
                isDark: isDark,
                textColor: textColor,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPickerOption({
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    required bool isDark,
    required Color textColor,
  }) {
    return Material(
      color: isDark ? Colors.white.withOpacity(0.05) : AppColors.bgLightGrayColor,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.primaryColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: isDark ? Colors.white54 : AppColors.fontDarkGrayColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: isDark ? Colors.white30 : AppColors.grayMedium),
            ],
          ),
        ),
      ),
    );
  }
}
