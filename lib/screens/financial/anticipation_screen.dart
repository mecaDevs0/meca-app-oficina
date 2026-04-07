import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';

class AnticipationScreen extends StatefulWidget {
  const AnticipationScreen({Key? key}) : super(key: key);

  @override
  State<AnticipationScreen> createState() => _AnticipationScreenState();
}

class _AnticipationScreenState extends State<AnticipationScreen> {
  bool _isLoading = true;
  bool _isSimulating = false;
  bool _isCreating = false;

  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _anticipations = [];
  Map<String, dynamic>? _simulation;
  String? _errorMessage;

  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String? _workshopId;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    await _apiService.loadToken();
    final id = await _apiService.getWorkshopId();
    if (!mounted) return;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sessão inválida. Faça login novamente.';
      });
      return;
    }
    setState(() => _workshopId = id);
    await _loadData();
  }

  void _safeSetState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Future<void> _loadData() async {
    _safeSetState(() {
      _isLoading = true;
      _errorMessage = null;
      _simulation = null;
    });

    try {
      final results = await Future.wait([
        _apiService.getAsaasBalance(_workshopId!),
        _apiService.listAnticipations(_workshopId!),
      ]);

      final balanceRes = results[0];
      final anticipationsRes = results[1];

      _safeSetState(() {
        if (balanceRes['success'] == true) {
          _balance = (balanceRes['data'] as Map?)?.cast<String, dynamic>();
        }
        if (anticipationsRes['success'] == true) {
          final raw = anticipationsRes['data'];
          if (raw is List) {
            _anticipations = raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
          } else if (raw is Map && raw['data'] is List) {
            _anticipations = (raw['data'] as List)
                .map((e) => (e as Map).cast<String, dynamic>())
                .toList();
          } else {
            _anticipations = [];
          }
        }
      });
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao carregar dados: ${e.toString()}');
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _simulate() async {
    if (_workshopId == null) return;
    _safeSetState(() {
      _isSimulating = true;
      _simulation = null;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.simulateAnticipation(_workshopId!, {});
      if (!mounted) return;
      if (res['success'] == true) {
        _safeSetState(() {
          _simulation = (res['data'] as Map?)?.cast<String, dynamic>();
        });
      } else {
        _safeSetState(() => _errorMessage = res['error']?.toString() ?? 'Erro ao simular');
      }
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao simular: ${e.toString()}');
    } finally {
      _safeSetState(() => _isSimulating = false);
    }
  }

  Future<void> _confirm() async {
    if (_workshopId == null || _simulation == null) return;

    final ok = await _showConfirmDialog();
    if (!ok || !mounted) return;

    _safeSetState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.createAnticipation(_workshopId!, {});
      if (!mounted) return;
      if (res['success'] == true) {
        _safeSetState(() => _simulation = null);
        _showSuccessSnack('Antecipação solicitada com sucesso.');
        await _loadData();
      } else {
        _safeSetState(() => _errorMessage = res['error']?.toString() ?? 'Erro ao criar antecipação');
      }
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao criar antecipação: ${e.toString()}');
    } finally {
      _safeSetState(() => _isCreating = false);
    }
  }

  Future<void> _cancel(String anticipationId) async {
    if (_workshopId == null) return;

    final ok = await _showCancelDialog();
    if (!ok || !mounted) return;

    try {
      final res = await _apiService.cancelAnticipation(_workshopId!, anticipationId);
      if (!mounted) return;
      if (res['success'] == true) {
        _showSuccessSnack('Antecipação cancelada.');
        await _loadData();
      } else {
        _safeSetState(
            () => _errorMessage = res['error']?.toString() ?? 'Erro ao cancelar');
      }
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao cancelar: ${e.toString()}');
    }
  }

  Future<bool> _showConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar antecipação'),
        content: const Text(
          'Deseja confirmar a solicitação de antecipação? Os valores e taxas apresentados na simulação serão aplicados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C977),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  Future<bool> _showCancelDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar antecipação'),
        content: const Text('Deseja cancelar esta solicitação de antecipação?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar antecipação'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

  void _showSuccessSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF00C977),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
        final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
        final secondaryTextColor =
            isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
        final cardColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
        final borderColor =
            isDark ? const Color(0xFF065F46) : const Color(0xFF00C977);

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
              'Antecipacao de Recebiveis',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: textColor,
              ),
            ),
          ),
          body: _isLoading
              ? AnimationWidgets.buildLoadingWidget(
                  message: 'Carregando dados de antecipação...')
              : RefreshIndicator(
                  onRefresh: _loadData,
                  child: CustomScrollView(
                    physics: const BouncingScrollPhysics(
                        parent: AlwaysScrollableScrollPhysics()),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_errorMessage != null)
                                _buildErrorBanner(
                                  _errorMessage!,
                                  textColor,
                                  secondaryTextColor,
                                ),
                              _buildBalanceCard(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                              const SizedBox(height: 16),
                              _buildSimulationSection(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Solicitacoes de Antecipacao',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildAnticipationsList(
                                cardColor: cardColor,
                                borderColor: borderColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                              ),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildErrorBanner(
    String message,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFFB91C1C),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceCard({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final available = _balance?['balance'] ?? _balance?['available'] ?? _balance?['availableBalance'];
    final pending = _balance?['pendingBalance'] ?? _balance?['pending'];
    final transferred = _balance?['transferredBalance'] ?? _balance?['transferred'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C977).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet,
                    color: Color(0xFF00C977), size: 24),
              ),
              const SizedBox(width: 12),
              Text(
                'Saldo Asaas',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildBalanceRow(
            label: 'Saldo disponivel',
            value: available,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            highlight: true,
          ),
          if (pending != null) ...[
            const SizedBox(height: 12),
            _buildBalanceRow(
              label: 'Saldo a receber',
              value: pending,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
          if (transferred != null) ...[
            const SizedBox(height: 12),
            _buildBalanceRow(
              label: 'Total transferido',
              value: transferred,
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
          if (_balance == null || _balance!.isEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Dados de saldo indisponiveis',
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow({
    required String label,
    required dynamic value,
    required Color textColor,
    required Color secondaryTextColor,
    bool highlight = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            fontSize: highlight ? 22 : 15,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
            color: highlight ? const Color(0xFF00C977) : textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildSimulationSection({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Solicitar Antecipacao',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Simule para ver os valores e taxas antes de confirmar.',
          style: TextStyle(
            fontSize: 14,
            color: secondaryTextColor,
          ),
        ),
        const SizedBox(height: 16),
        if (_simulation != null)
          _buildSimulationResult(
            cardColor: cardColor,
            borderColor: borderColor,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
        if (_simulation == null)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isSimulating ? null : _simulate,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C977),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: _isSimulating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.calculate_outlined),
              label: Text(
                _isSimulating ? 'Simulando...' : 'Simular antecipacao',
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSimulationResult({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final sim = _simulation!;
    final grossValue = sim['totalGrossValue'] ?? sim['gross_value'] ?? sim['value'];
    final netValue = sim['totalNetValue'] ?? sim['net_value'] ?? sim['netValue'];
    final fee = sim['anticipationFee'] ?? sim['fee'] ?? sim['totalFee'];
    final feePercent = sim['anticipationFeePercent'] ?? sim['fee_percent'] ?? sim['feePercent'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF00C977).withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF00C977).withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline,
                  color: Color(0xFF00C977), size: 22),
              const SizedBox(width: 8),
              Text(
                'Simulacao de antecipacao',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSimRow(
            label: 'Valor bruto',
            value: _formatCurrency(grossValue),
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
          ),
          if (feePercent != null) ...[
            const SizedBox(height: 10),
            _buildSimRow(
              label: 'Taxa de antecipacao',
              value: _formatPercent(feePercent),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
          if (fee != null) ...[
            const SizedBox(height: 10),
            _buildSimRow(
              label: 'Custo da antecipacao',
              value: _formatCurrency(fee),
              textColor: textColor,
              secondaryTextColor: secondaryTextColor,
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: Color(0xFF00C977)),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Valor liquido a receber',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
              Text(
                _formatCurrency(netValue),
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF00C977),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _safeSetState(() => _simulation = null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryTextColor,
                    side: BorderSide(color: secondaryTextColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00C977),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'Confirmar',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimRow({
    required String label,
    required String value,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(fontSize: 14, color: secondaryTextColor)),
        Text(value,
            style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildAnticipationsList({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    if (_anticipations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 48, color: secondaryTextColor),
            const SizedBox(height: 16),
            Text(
              'Nenhuma solicitacao encontrada',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Suas solicitacoes de antecipacao aparecerao aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _anticipations.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: secondaryTextColor.withOpacity(0.15),
        ),
        itemBuilder: (context, index) => _buildAnticipationItem(
          _anticipations[index],
          textColor: textColor,
          secondaryTextColor: secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildAnticipationItem(
    Map<String, dynamic> item, {
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final status = (item['status'] ?? '').toString().toUpperCase();
    final id = (item['id'] ?? item['anticipationId'] ?? '').toString();
    final totalValue = item['totalValue'] ?? item['value'] ?? item['grossValue'];
    final netValue = item['totalNetValue'] ?? item['netValue'] ?? item['net_value'];
    final createdAt = _formatDate(item['dateCreated'] ?? item['created_at']);
    final canCancel = status == 'PENDING' || status == 'AGUARDANDO_APROVACAO';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatusBadge(status),
                    const SizedBox(height: 6),
                    Text(
                      createdAt,
                      style: TextStyle(
                          fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatCurrency(totalValue),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  if (netValue != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Liquido: ${_formatCurrency(netValue)}',
                      style: TextStyle(
                          fontSize: 12, color: secondaryTextColor),
                    ),
                  ],
                ],
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _cancel(id),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFEF4444),
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                icon: const Icon(Icons.cancel_outlined, size: 16),
                label: const Text(
                  'Cancelar solicitacao',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case 'APPROVED':
      case 'APROVADO':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Aprovado';
        break;
      case 'PENDING':
      case 'AGUARDANDO_APROVACAO':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB45309);
        label = 'Pendente';
        break;
      case 'DENIED':
      case 'NEGADO':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Negado';
        break;
      case 'CANCELLED':
      case 'CANCELADO':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Cancelado';
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized =
          value.replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    return null;
  }

  String _formatCurrency(dynamic value) {
    final parsed = _toDouble(value);
    if (parsed == null) return 'R\$ 0,00';
    return _currencyFormat.format(parsed);
  }

  String _formatPercent(dynamic value) {
    final parsed = _toDouble(value);
    if (parsed == null) return '—';
    final pct = parsed > 1 ? parsed : (parsed * 100);
    return '${pct.toStringAsFixed(2)}%';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data nao informada';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dt.toLocal());
    } catch (_) {
      return value.toString();
    }
  }
}
