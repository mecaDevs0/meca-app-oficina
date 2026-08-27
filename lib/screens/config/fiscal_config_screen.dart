import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class FiscalConfigScreen extends StatefulWidget {
  const FiscalConfigScreen({Key? key}) : super(key: key);

  @override
  State<FiscalConfigScreen> createState() => _FiscalConfigScreenState();
}

class _FiscalConfigScreenState extends State<FiscalConfigScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _nfEnabled = false;
  final ApiService _apiService = ApiService();
  final _serviceCodeController = TextEditingController();
  final _serviceNameController = TextEditingController();
  final _issRateController = TextEditingController();
  final _inscricaoMunicipalController = TextEditingController();
  String _taxRegime = 'SIMPLES_NACIONAL';

  @override
  void initState() {
    super.initState();
    _loadConfig();
  }

  @override
  void dispose() {
    _serviceCodeController.dispose();
    _serviceNameController.dispose();
    _issRateController.dispose();
    _inscricaoMunicipalController.dispose();
    super.dispose();
  }

  Future<void> _loadConfig() async {
    try {
      await _apiService.loadToken();
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      final res = await _apiService.get('/workshop/$workshopId/fiscal-config');
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'] as Map<String, dynamic>;
        setState(() {
          _nfEnabled = data['nf_enabled'] == true;
          _serviceCodeController.text = data['nf_municipal_service_code'] ?? '';
          _serviceNameController.text = data['nf_municipal_service_name'] ?? '';
          _issRateController.text = (data['nf_iss_rate'] ?? 5.0).toString();
          _inscricaoMunicipalController.text = data['inscricao_municipal'] ?? '';
          _taxRegime = data['tax_regime'] ?? 'SIMPLES_NACIONAL';
        });
      }
    } catch (e) {
      debugPrint('Erro ao carregar config fiscal: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveConfig() async {
    if (_nfEnabled && _serviceCodeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código do serviço municipal é obrigatório'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }
    if (_nfEnabled && _serviceNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nome do serviço municipal é obrigatório'), backgroundColor: Color(0xFFEF4444)),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await _apiService.loadToken();
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) return;
      final res = await _apiService.put('/workshop/$workshopId/fiscal-config', {
        'nf_enabled': _nfEnabled,
        'nf_municipal_service_code': _serviceCodeController.text.trim(),
        'nf_municipal_service_name': _serviceNameController.text.trim(),
        'nf_iss_rate': double.tryParse(_issRateController.text) ?? 5.0,
        'inscricao_municipal': _inscricaoMunicipalController.text.trim(),
        'tax_regime': _taxRegime,
      });
      if (res['success'] == true && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuração fiscal salva!'), backgroundColor: Color(0xFF00C977)),
        );
      } else {
        final error = res['error'] ?? 'Erro ao salvar';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString()), backgroundColor: const Color(0xFFEF4444)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _handleBack() async {
    if (!_nfEnabled) return true;
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          icon: const Icon(Icons.description_outlined, color: Color(0xFF00C977), size: 48),
          title: Text(
            'Dados fiscais incompletos',
            style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w700),
          ),
          content: Text(
            'Você ativou a emissão automática de NF. Preencha os dados fiscais para que as notas sejam emitidas corretamente após cada pagamento.',
            style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text('Voltar mesmo assim', style: TextStyle(color: isDark ? Colors.white54 : Colors.black45)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, false),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C977), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: const Text('Preencher dados'),
            ),
          ],
        );
      },
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F5F5);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
        final secondaryText = isDark ? Colors.white70 : Colors.black54;
        final borderColor = isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08);
        final inputBg = isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0);

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return;
            final shouldPop = await _handleBack();
            if (shouldPop && context.mounted) Navigator.pop(context);
          },
          child: Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20),
              onPressed: () async {
                final shouldPop = await _handleBack();
                if (shouldPop && context.mounted) Navigator.pop(context);
              },
            ),
            title: Text('Nota Fiscal', style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.w700)),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle card
                      Container(
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: borderColor),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Emitir NF automaticamente', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Ao confirmar cada pagamento', style: TextStyle(color: secondaryText, fontSize: 12)),
                                ],
                              ),
                            ),
                            Switch(
                              value: _nfEnabled,
                              onChanged: (v) => setState(() => _nfEnabled = v),
                              activeTrackColor: const Color(0xFF00C977),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info banner
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF60A5FA).withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF60A5FA).withValues(alpha: 0.15)),
                        ),
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.info_outline, color: Color(0xFF60A5FA), size: 18),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'A MECA arca com o custo de emissão da NF (R\$ 0,49 por nota). Não há cobrança adicional para sua oficina.',
                                style: TextStyle(color: secondaryText, fontSize: 12, height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (_nfEnabled) ...[
                        const SizedBox(height: 24),
                        Container(
                          decoration: BoxDecoration(
                            color: cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: borderColor),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Dados Fiscais', style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 16),
                              Text('Código do serviço municipal', style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serviceCodeController,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 1401',
                                  hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Para oficinas mecânicas, geralmente é 1401', style: TextStyle(color: secondaryText, fontSize: 10)),
                              const SizedBox(height: 16),
                              Text('Nome do serviço municipal', style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _serviceNameController,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: '14.01 - Manutenção e reparação de veículos',
                                  hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Alíquota ISS (%)', style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: 120,
                                child: TextField(
                                  controller: _issRateController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  style: TextStyle(color: textColor, fontSize: 14),
                                  decoration: InputDecoration(
                                    hintText: '5.00',
                                    hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                                    filled: true,
                                    fillColor: inputBg,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    suffixText: '%',
                                    suffixStyle: TextStyle(color: secondaryText, fontSize: 14),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Geralmente entre 2% e 5%', style: TextStyle(color: secondaryText, fontSize: 10)),
                              const SizedBox(height: 16),
                              Text('Inscrição Municipal (opcional)', style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              TextField(
                                controller: _inscricaoMunicipalController,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: 'Ex: 12345678',
                                  hintStyle: TextStyle(color: secondaryText.withValues(alpha: 0.5)),
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text('Regime Tributário', style: TextStyle(color: secondaryText, fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _taxRegime,
                                dropdownColor: cardColor,
                                style: TextStyle(color: textColor, fontSize: 14),
                                decoration: InputDecoration(
                                  filled: true,
                                  fillColor: inputBg,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 'SIMPLES_NACIONAL', child: Text('Simples Nacional')),
                                  DropdownMenuItem(value: 'LUCRO_PRESUMIDO', child: Text('Lucro Presumido')),
                                  DropdownMenuItem(value: 'LUCRO_REAL', child: Text('Lucro Real')),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _taxRegime = val);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveConfig,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C977),
                            foregroundColor: const Color(0xFF0A0A0A),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF0A0A0A)))
                              : const Text('Salvar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
