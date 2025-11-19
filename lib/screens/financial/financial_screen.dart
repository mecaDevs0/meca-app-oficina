import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _financialData;
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Future<void> _loadFinancialData() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      final response = await _apiService.getFinancialSummary();
      if (response['success']) {
        _safeSetState(() {
          _financialData = response['data'];
        });
      }
      
    } catch (e) {
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final bgColor = themeService.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
    final textColor = themeService.isDarkMode ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
    final secondaryTextColor = themeService.isDarkMode ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
    final cardColor = themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
    final cardBorderColor = themeService.isDarkMode ? const Color(0xFF065F46) : const Color(0xFF00C977);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: _isLoading
            ? AnimationWidgets.buildLoadingWidget(message: 'Carregando dados financeiros...')
            : RefreshIndicator(
                onRefresh: _loadFinancialData,
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Financeiro',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.5,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Acompanhe faturamento, estatísticas e transações em tempo real.',
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          children: [
                            _buildSummarySection(
                              cardColor: cardColor,
                              borderColor: cardBorderColor,
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                            const SizedBox(height: 16),
                            _buildStatsGrid(
                              cardColor: cardColor,
                              borderColor: cardBorderColor,
                              textColor: textColor,
                              secondaryTextColor: secondaryTextColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Transações Recentes',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildTransactionsList(
                          cardColor: cardColor,
                          borderColor: cardBorderColor,
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildSummarySection({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final totals = (_financialData?['totals'] as Map?)?.cast<String, dynamic>() ?? {};

    final summaryItems = [
      {
        'title': 'Receita líquida',
        'value': totals['net'],
        'icon': Icons.payments,
        'color': const Color(0xFF10B981),
        'subtitle': 'Valores disponíveis após taxas',
      },
      {
        'title': 'Receita bruta',
        'value': totals['gross'],
        'icon': Icons.request_quote,
        'color': const Color(0xFF2563EB),
        'subtitle': 'Somatório dos pagamentos aprovados',
      },
      {
        'title': 'Taxas MECA',
        'value': totals['meca_fee'],
        'icon': Icons.fact_check,
        'color': const Color(0xFF8B5CF6),
        'subtitle': 'Comissão da plataforma',
      },
      {
        'title': 'Taxas PagBank',
        'value': totals['pagbank_fee'],
        'icon': Icons.account_balance,
        'color': const Color(0xFFF59E0B),
        'subtitle': 'Custos de processamento',
        'trailingLabel': 'Pendências',
        'trailingValue': totals['pending_gross'],
      },
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                title: summaryItems[0]['title'] as String,
                amount: summaryItems[0]['value'],
                icon: summaryItems[0]['icon'] as IconData,
                color: summaryItems[0]['color'] as Color,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                subtitle: summaryItems[0]['subtitle'] as String,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFinancialCard(
                title: summaryItems[1]['title'] as String,
                amount: summaryItems[1]['value'],
                icon: summaryItems[1]['icon'] as IconData,
                color: summaryItems[1]['color'] as Color,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                subtitle: summaryItems[1]['subtitle'] as String,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildFinancialCard(
                title: summaryItems[2]['title'] as String,
                amount: summaryItems[2]['value'],
                icon: summaryItems[2]['icon'] as IconData,
                color: summaryItems[2]['color'] as Color,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                subtitle: summaryItems[2]['subtitle'] as String,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildFinancialCard(
                title: summaryItems[3]['title'] as String,
                amount: summaryItems[3]['value'],
                icon: summaryItems[3]['icon'] as IconData,
                color: summaryItems[3]['color'] as Color,
                cardColor: cardColor,
                borderColor: borderColor,
                textColor: textColor,
                secondaryTextColor: secondaryTextColor,
                subtitle: summaryItems[3]['subtitle'] as String,
                trailingLabel: 'Pendências',
                trailingValue: summaryItems[3]['trailingValue'],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required dynamic amount,
    required IconData icon,
    required Color color,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    String? subtitle,
    String? trailingLabel,
    dynamic trailingValue,
  }) {
    final amountLabel = _formatCurrency(amount, fallback: 'R\$ 0,00');
    final trailing = trailingLabel != null
        ? _formatCurrency(trailingValue, fallback: 'R\$ 0,00')
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 14),
            Divider(color: secondaryTextColor.withOpacity(0.2)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  trailingLabel!,
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                  ),
                ),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatsGrid({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final totals = (_financialData?['totals'] as Map?)?.cast<String, dynamic>() ?? {};
    final metrics = (_financialData?['metrics'] as Map?)?.cast<String, dynamic>() ?? {};

    final stats = [
      {
        'title': 'Transações pagas',
        'value': (metrics['paid_transactions'] ?? 0).toString(),
        'icon': Icons.check_circle,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Ticket médio',
        'value': _formatCurrency(metrics['average_ticket'], fallback: '—'),
        'icon': Icons.show_chart,
        'color': const Color(0xFF2563EB),
      },
      {
        'title': 'Taxa MECA efetiva',
        'value': _formatPercent(metrics['effective_meca_fee']),
        'icon': Icons.percent,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'Pendências',
        'value': _formatCurrency(totals['pending_gross'], fallback: 'R\$ 0,00'),
        'icon': Icons.pending_actions,
        'color': const Color(0xFFF97316),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.5,
      ),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 8),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionsList({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final transactions = (_financialData?['recent_transactions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    if (transactions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
        ),
        child: Column(
          children: [
            const Icon(
              Icons.receipt_long,
              size: 48,
              color: Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação recente',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Assim que os clientes efetuarem pagamentos, eles aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: transactions.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          color: secondaryTextColor.withOpacity(0.15),
        ),
        itemBuilder: (context, index) => _buildTransactionCard(
          transactions[index],
          textColor,
          secondaryTextColor,
        ),
      ),
    );
  }

  Widget _buildTransactionCard(
    Map<String, dynamic> transaction,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final status = (transaction['status'] ?? 'pending').toString();
    final serviceName = (transaction['service_name'] ?? 'Serviço').toString();
    final method = (transaction['payment_method'] ?? 'Desconhecido').toString().toUpperCase();
    final installments = transaction['installments'] ?? 1;
    final createdAt = _formatDate(transaction['created_at']);

    final netAmount = _formatCurrency(transaction['net_amount'], fallback: '—');
    final mecaFeeAmount = _formatCurrency(transaction['meca_fee_amount'], fallback: '—');
    final pagbankFeeAmount = _formatCurrency(transaction['pagbank_fee_amount'], fallback: '—');
    final grossAmount = _formatCurrency(transaction['gross_amount'], fallback: 'R\$ 0,00');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                    Text(
                      serviceName,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$method${installments is num && installments > 1 ? ' • ${installments}x' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      createdAt,
                      style: TextStyle(
                        fontSize: 12,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                grossAmount,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatusChip(status, secondaryTextColor, textColor),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildAmountDetail('Taxa MECA', mecaFeeAmount, secondaryTextColor, textColor),
              const SizedBox(width: 12),
              _buildAmountDetail('Taxa PagBank', pagbankFeeAmount, secondaryTextColor, textColor),
              const SizedBox(width: 12),
              _buildAmountDetail('Líquido', netAmount, secondaryTextColor, textColor,
                  highlight: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status, Color secondaryTextColor, Color textColor) {
    Color background;
    Color foreground;
    String label;

    switch (status) {
      case 'approved':
        background = const Color(0xFFDCFCE7);
        foreground = const Color(0xFF15803D);
        label = 'Pago';
        break;
      case 'pending':
        background = const Color(0xFFFFF7ED);
        foreground = const Color(0xFFB45309);
        label = 'Pendente';
        break;
      case 'cancelled':
        background = const Color(0xFFFEE2E2);
        foreground = const Color(0xFFB91C1C);
        label = 'Cancelado';
        break;
      default:
        background = secondaryTextColor.withOpacity(0.12);
        foreground = textColor;
        label = status.toUpperCase();
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  Widget _buildAmountDetail(
    String label,
    String value,
    Color labelColor,
    Color textColor, {
    bool highlight = false,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: labelColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: highlight ? FontWeight.w700 : FontWeight.w600,
              color: highlight ? textColor : textColor.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    return null;
  }

  String _formatCurrency(dynamic value, {String fallback = '—'}) {
    final parsed = _toDouble(value);
    if (parsed == null) return fallback;
    return _currencyFormat.format(parsed);
  }

  String _formatPercent(dynamic value, {String fallback = '—'}) {
    final parsed = _toDouble(value);
    if (parsed == null) return fallback;
    return '${(parsed * 100).toStringAsFixed(2)}%';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não informada';
    try {
      final dateTime = value is DateTime ? value : DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dateTime.toLocal());
    } catch (_) {
      return value.toString();
    }
  }
}