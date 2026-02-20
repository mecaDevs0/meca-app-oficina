import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';

class InstallmentConfigScreen extends StatefulWidget {
  const InstallmentConfigScreen({Key? key}) : super(key: key);

  @override
  State<InstallmentConfigScreen> createState() => _InstallmentConfigScreenState();
}

class _InstallmentConfigScreenState extends State<InstallmentConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _acceptsInstallment = true;
  int _maxInstallments = 12;
  int _originalMaxInstallments = 12;
  bool _originalAcceptsInstallment = true;
  final ApiService _apiService = ApiService();

  bool get _hasUnsavedChanges =>
      _maxInstallments != _originalMaxInstallments ||
      _acceptsInstallment != _originalAcceptsInstallment;

  @override
  void initState() {
    super.initState();
    _loadInstallmentConfig();
  }

  Future<void> _loadInstallmentConfig() async {
    setState(() => _isLoading = true);
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }
      await _apiService.loadToken();
      final response = await _apiService.getWorkshopProfile();
      if (response['success'] && response['data'] != null) {
        final workshop = response['data']['workshop'] ?? response['data'] as Map<String, dynamic>?;
        if (workshop != null) {
          final accepts = workshop['accepts_installment'] ?? true;
          final max = (workshop['max_installments'] is int)
              ? (workshop['max_installments'] as int).clamp(1, 24)
              : (int.tryParse(workshop['max_installments']?.toString() ?? '12') ?? 12).clamp(1, 24);
          setState(() {
            _acceptsInstallment = accepts;
            _maxInstallments = max;
            _originalAcceptsInstallment = accepts;
            _originalMaxInstallments = max;
          });
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _saveInstallmentConfig() async {
    setState(() => _isSaving = true);
    try {
      final response = await _apiService.updateWorkshopProfile({
        'accepts_installment': _acceptsInstallment,
        'max_installments': _maxInstallments,
      });
      if (!mounted) return;
      if (response['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Salvo'),
            backgroundColor: Theme.of(context).colorScheme.primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['error']}'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _originalMaxInstallments = _maxInstallments;
          _originalAcceptsInstallment = _acceptsInstallment;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasUnsavedChanges) return true;
    final exit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alterações não salvas'),
        content: const Text(
          'Você alterou a configuração de parcelamento e não salvou. Deseja sair sem salvar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sair sem salvar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, false);
              _saveInstallmentConfig();
            },
            child: const Text('Salvar e sair'),
          ),
        ],
      ),
    );
    return exit ?? false;
  }

  static const Color _verdeMeca = Color(0xFF00C977);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final mecaFeePercent = (AppConfig.mecaPlatformFee * 100).toStringAsFixed(0);
    final surface = isDark ? const Color(0xFF161616) : Colors.white;
    final onSurface = isDark ? Colors.white : const Color(0xFF1A1A);
    final muted = isDark ? const Color(0xFF737373) : const Color(0xFF737373);
    // Tema escuro: usar verde MECA como destaque (em vez de azul)
    final accentColor = isDark ? _verdeMeca : theme.colorScheme.primary;

    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        return PopScope(
          canPop: !_hasUnsavedChanges,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final exit = await _onWillPop();
            if (exit && mounted) Navigator.of(context).pop();
          },
          child: Scaffold(
          backgroundColor: isDark ? const Color(0xFF0C0C0C) : const Color(0xFFF5F5F5),
          appBar: AppBar(
            title: const Text('Parcelamento'),
            backgroundColor: isDark ? const Color(0xFF0C0C0C) : Colors.white,
            foregroundColor: onSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
          ),
          body: _isLoading
              ? Center(
                  child: CupertinoActivityIndicator(
                    color: accentColor,
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Seção principal — estilo iOS Settings
                      Container(
                        decoration: BoxDecoration(
                          color: surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Toggle — linha estilo iOS
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Aceitar parcelamento',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w500,
                                            color: onSurface,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Clientes podem pagar em parcelas no cartão',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: muted,
                                            height: 1.2,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  CupertinoSwitch(
                                    value: _acceptsInstallment,
                                    onChanged: _isSaving ? null : (v) => setState(() => _acceptsInstallment = v),
                                    activeColor: accentColor,
                                  ),
                                ],
                              ),
                            ),
                            if (_acceptsInstallment) ...[
                              Divider(
                                height: 1,
                                indent: 16,
                                endIndent: 16,
                                color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Máximo de parcelas',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w400,
                                        color: muted,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    // Valor grande — estilo iOS
                                    Center(
                                      child: Text.rich(
                                        TextSpan(
                                          text: '$_maxInstallments',
                                          style: TextStyle(
                                            fontSize: 56,
                                            fontWeight: FontWeight.w200,
                                            color: accentColor,
                                            letterSpacing: -2,
                                            height: 1,
                                          ),
                                          children: [
                                            TextSpan(
                                              text: ' parcelas',
                                              style: TextStyle(
                                                fontSize: 22,
                                                fontWeight: FontWeight.w400,
                                                color: muted,
                                                letterSpacing: -0.5,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    // Atalhos — Segmented Control estilo iOS (sempre visíveis)
                                    LayoutBuilder(
                                      builder: (context, constraints) {
                                        return Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [3, 6, 12, 18, 24].map((n) {
                                            final isSelected = _maxInstallments == n;
                                            return GestureDetector(
                                              onTap: _isSaving ? null : () => setState(() => _maxInstallments = n),
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                                decoration: BoxDecoration(
                                                  color: isSelected
                                                      ? accentColor
                                                      : (isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA)),
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                                child: Text(
                                                  '$n×',
                                                  style: TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                    color: isSelected
                                                        ? Colors.white
                                                        : (isDark ? Colors.white : const Color(0xFF1C1C1E)),
                                                  ),
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                        );
                                      },
                                    ),
                                    const SizedBox(height: 28),
                                    // Slider Cupertino — nativo iOS
                                    CupertinoSlider(
                                      value: _maxInstallments.toDouble(),
                                      min: 1,
                                      max: 24,
                                      divisions: 23,
                                      activeColor: accentColor,
                                      onChanged: _isSaving ? null : (v) => setState(() => _maxInstallments = v.round()),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            '1',
                                            style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w400),
                                          ),
                                          Text(
                                            '24',
                                            style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w400),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'O MECA cuida do parcelamento. Você recebe o valor do serviço (descontada a taxa).',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: muted,
                                        height: 1.35,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Botão Salvar — estilo iOS
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                              child: SizedBox(
                                width: double.infinity,
                                height: 50,
                                child: CupertinoButton(
                                  padding: EdgeInsets.zero,
                                  borderRadius: BorderRadius.circular(12),
                                  color: accentColor,
                                  disabledColor: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFE5E5EA),
                                  onPressed: (_isSaving || !_hasUnsavedChanges) ? null : _saveInstallmentConfig,
                                  child: _isSaving
                                      ? const CupertinoActivityIndicator(color: Colors.white)
                                      : Text(
                                          'Salvar',
                                          style: TextStyle(
                                            fontSize: 17,
                                            fontWeight: FontWeight.w600,
                                            color: (_isSaving || !_hasUnsavedChanges) ? muted : Colors.white,
                                          ),
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Nota — estilo iOS footer
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              CupertinoIcons.info_circle,
                              size: 14,
                              color: muted,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Taxa de $mecaFeePercent% sobre pagamentos. Juros do parcelamento são do PagBank.',
                                style: TextStyle(fontSize: 13, color: muted, height: 1.4),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        );
      },
    );
  }
}
