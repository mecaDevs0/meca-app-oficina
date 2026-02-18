import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({Key? key}) : super(key: key);

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadReferrals();
  }

  Future<void> _loadReferrals() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final result = await _apiService.getReferrals();
      if (!mounted) return;
      if (result['success'] == true && result['data'] != null) {
        setState(() {
          _data = Map<String, dynamic>.from(result['data'] as Map);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = result['error']?.toString() ?? 'Erro ao carregar dados';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _copyCode(String? code) async {
    if (code == null || code.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Código copiado!'),
        backgroundColor: Color(0xFF00C977),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareWhatsApp(String? code) async {
    if (code == null || code.isEmpty) return;
    final text = Uri.encodeComponent(
      'Cadastre sua oficina no MECA usando meu código de indicação: $code\n\n'
      'Você ganha as vantagens da plataforma e eu posso ganhar 50% de desconto na taxa MECA ao indicar 5 oficinas que completem o primeiro serviço.',
    );
    final uri = Uri.parse('https://wa.me/?text=$text');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível abrir o WhatsApp'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, child) {
        final isDark = themeService.isDarkMode;
        final bgColor = ThemeService.getBackgroundColor(isDark);
        final textColor = ThemeService.getTextColor(isDark);
        final secondaryText = ThemeService.getSecondaryTextColor(isDark);

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Indique e Ganhe',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
            iconTheme: IconThemeData(color: textColor),
          ),
          body: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00C977)),
                  ),
                )
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline, size: 48, color: secondaryText),
                            const SizedBox(height: 16),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: secondaryText),
                            ),
                            const SizedBox(height: 24),
                            TextButton.icon(
                              onPressed: _loadReferrals,
                              icon: const Icon(Icons.refresh),
                              label: const Text('Tentar novamente'),
                            ),
                          ],
                        ),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCurrentFeeCard(isDark, textColor, secondaryText),
                          const SizedBox(height: 24),
                          _buildCodeCard(isDark, textColor, secondaryText),
                          const SizedBox(height: 24),
                          _buildProgressCard(isDark, textColor, secondaryText),
                        ],
                      ),
                    ),
        );
      },
    );
  }

  Widget _buildCurrentFeeCard(bool isDark, Color textColor, Color secondaryText) {
    final fee = _data?['current_fee_percentage'] ?? 12;
    final isReduced = _data?['is_fee_reduced'] == true;
    final feeReducedUntilRaw = _data?['fee_reduced_until']?.toString();
    DateTime? feeReducedUntil;
    if (feeReducedUntilRaw != null && feeReducedUntilRaw.isNotEmpty) {
      feeReducedUntil = DateTime.tryParse(feeReducedUntilRaw);
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isReduced
            ? const Color(0xFF00C977).withOpacity(0.15)
            : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
        borderRadius: BorderRadius.circular(16),
        border: isReduced
            ? Border.all(color: const Color(0xFF00C977).withOpacity(0.5), width: 1)
            : null,
      ),
      child: Row(
        children: [
          Icon(
            isReduced ? Icons.celebration : Icons.percent,
            color: isReduced ? const Color(0xFF00C977) : secondaryText,
            size: 32,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sua taxa atual',
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  isReduced ? '6% (Parabéns!)' : '$fee%',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isReduced ? const Color(0xFF00C977) : textColor,
                  ),
                ),
                if (isReduced) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      'Você atingiu a meta de 5 indicações ativas. Benefício por 1 mês.',
                      style: TextStyle(fontSize: 12, color: secondaryText),
                    ),
                  ),
                  if (feeReducedUntil != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Válido até: ${feeReducedUntil.day.toString().padLeft(2, '0')}/${feeReducedUntil.month.toString().padLeft(2, '0')}/${feeReducedUntil.year}',
                        style: TextStyle(fontSize: 12, color: secondaryText, fontWeight: FontWeight.w500),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeCard(bool isDark, Color textColor, Color secondaryText) {
    final code = _data?['referral_code']?.toString() ?? '—';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seu código de indicação',
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.black26 : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    code,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: textColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                onPressed: () => _copyCode(_data?['referral_code']?.toString()),
                icon: const Icon(Icons.copy),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  foregroundColor: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                onPressed: () => _shareWhatsApp(_data?['referral_code']?.toString()),
                icon: const Icon(Icons.share),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFF25D366),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Compartilhe com outras oficinas. Quando 5 delas completarem o primeiro serviço pago, sua taxa cai para 6% por 1 mês.',
            style: TextStyle(fontSize: 12, color: secondaryText),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressCard(bool isDark, Color textColor, Color secondaryText) {
    final totalReferrals = int.tryParse('${_data?['total_referrals']}') ?? 0;
    final active = int.tryParse('${_data?['active_referrals_count']}') ?? 0;
    final target = int.tryParse('${_data?['target_count']}') ?? 5;
    final missing = int.tryParse('${_data?['missing_for_discount']}') ?? 5;
    final isDone = _data?['is_fee_reduced'] == true;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Progresso',
            style: TextStyle(
              fontSize: 14,
              color: secondaryText,
            ),
          ),
          const SizedBox(height: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$totalReferrals oficina${totalReferrals == 1 ? '' : 's'} indicada${totalReferrals == 1 ? '' : 's'} ($active ativa${active == 1 ? '' : 's'})',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$active/$target indicações ativas (para o desconto)',
                style: TextStyle(fontSize: 13, color: secondaryText),
              ),
              if (!isDone && missing > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'Faltam $missing para 50% de desconto',
                  style: TextStyle(fontSize: 12, color: secondaryText),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: target > 0 ? (active / target).clamp(0.0, 1.0) : 0,
              minHeight: 10,
              backgroundColor: isDark ? Colors.black26 : Colors.white,
              valueColor: AlwaysStoppedAnimation<Color>(
                isDone ? const Color(0xFF00C977) : const Color(0xFF00C977),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Indicação "ativa" = oficina que já completou pelo menos 1 serviço pago.',
            style: TextStyle(fontSize: 11, color: secondaryText),
          ),
        ],
      ),
    );
  }
}
