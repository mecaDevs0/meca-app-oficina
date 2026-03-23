import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import 'bank_account_screen.dart';

class PagBankConfigScreen extends StatefulWidget {
  const PagBankConfigScreen({super.key});

  @override
  State<PagBankConfigScreen> createState() => _PagBankConfigScreenState();
}

class _PagBankConfigScreenState extends State<PagBankConfigScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic>? _asaasStatus;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadData();
    });
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    if (state == AppLifecycleState.resumed) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    _safeSetState(() { _isLoading = true; _errorMessage = null; });
    try {
      await _apiService.loadToken();
      final workshopId = await _apiService.getWorkshopId();
      if (workshopId == null) {
        _safeSetState(() { _isLoading = false; _errorMessage = 'Usuário não autenticado'; });
        return;
      }
      final response = await _apiService.getAsaasStatus(workshopId);
      if (mounted) {
        _safeSetState(() {
          final raw = response['data'];
        _asaasStatus = raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{};
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _safeSetState(() { _isLoading = false; _errorMessage = e.toString(); });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        return Scaffold(
          backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
          appBar: AppBar(
            backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            title: Text(
              'Conta de Recebimento',
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF252940),
                fontWeight: FontWeight.bold,
              ),
            ),
            iconTheme: IconThemeData(color: isDark ? Colors.white : const Color(0xFF252940)),
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
              : _errorMessage != null
                  ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
                  : _buildAccountStatus(isDark),
        );
      },
    );
  }

  Widget _buildAccountStatus(bool isDark) {
    final data = _asaasStatus ?? {};
    final bool onboarded = data['onboarded'] == true || data['asaas_wallet_id'] != null;
    final String status = (data['asaas_status'] ?? '').toString().toUpperCase();

    if (onboarded && status == 'ACTIVE') {
      return _buildStatusCard(
        isDark: isDark,
        icon: Icons.check_circle,
        iconColor: const Color(0xFF00C977),
        badgeColor: const Color(0xFF00C977).withOpacity(0.15),
        badgeText: 'Ativo',
        badgeTextColor: const Color(0xFF00C977),
        title: 'Conta ativa',
        subtitle: 'Você está recebendo normalmente.',
      );
    }

    if (onboarded && (status == 'PENDING' || status.isEmpty)) {
      return _buildStatusCard(
        isDark: isDark,
        icon: Icons.hourglass_top,
        iconColor: Colors.amber,
        badgeColor: Colors.amber.withOpacity(0.15),
        badgeText: 'Em análise',
        badgeTextColor: Colors.amber[800]!,
        title: 'Conta em análise',
        subtitle: 'Validação em até 2 dias úteis. Você será notificado quando ativada.',
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.12),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.orange, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              'Conta de recebimento não configurada',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF252940),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Configure seus dados bancários para receber pagamentos dos clientes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => const BankAccountScreen()),
                  );
                  if (updated == true) _loadData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Configurar dados bancários', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required Color badgeColor,
    required String badgeText,
    required Color badgeTextColor,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(icon, color: iconColor, size: 48),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badgeText, style: TextStyle(color: badgeTextColor, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF252940),
              ),
            ),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}
