import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../providers/notification_provider.dart';

class FinancialScreen extends StatefulWidget {
  const FinancialScreen({Key? key}) : super(key: key);

  @override
  State<FinancialScreen> createState() => _FinancialScreenState();
}

class _FinancialScreenState extends State<FinancialScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _financialData;
  Map<String, dynamic>? _anticipationSummary;
  bool _isAsaasOnboarded = false;
  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFinancialData();
    // Marcar badge financeiro como visto ao abrir a tela
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = Provider.of<NotificationProvider>(context, listen: false);
      provider.markFinancialBadgeSeen();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
      
      final results = await Future.wait([
        _apiService.getFinancialSummary(),
        _apiService.getProfile(),
      ]);

      final response = results[0];
      final profileResponse = results[1];

      if (response['success']) {
        _safeSetState(() {
          _financialData = response['data'];
        });
      }

      if (profileResponse['success'] == true) {
        final workshop = profileResponse['data'];
        if (workshop is Map) {
          final walletId = (workshop['asaas_wallet_id'] as String? ?? '').trim();
          _safeSetState(() => _isAsaasOnboarded = walletId.isNotEmpty);

          if (walletId.isNotEmpty) {
            final workshopId = await _apiService.getWorkshopId();
            if (workshopId != null && workshopId.isNotEmpty) {
              try {
                final summaryRes = await _apiService.getAnticipationSummary(workshopId);
                if (summaryRes['success'] == true && summaryRes['data'] is Map) {
                  _safeSetState(() {
                    _anticipationSummary = (summaryRes['data'] as Map).cast<String, dynamic>();
                  });
                }
              } catch (_) {}
            }
          }
        }
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
                              'Faturamento, métricas e transações.',
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryTextColor,
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (_isAsaasOnboarded)
                              _buildAnticipationCard(
                                cardColor: cardColor,
                                borderColor: cardBorderColor,
                                textColor: textColor,
                              )
                            else
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBorderColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: cardBorderColor.withOpacity(0.4)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.email_outlined, color: cardBorderColor, size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Para adiantar recebimentos, entre em contato com contato@mecabr.com',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: textColor,
                                        ),
                                      ),
                                    ),
                                  ],
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
                            const SizedBox(height: 12),
                            TextField(
                              controller: _searchController,
                              style: TextStyle(color: textColor, fontSize: 14),
                              onChanged: (value) => _safeSetState(() => _searchQuery = value.toLowerCase()),
                              decoration: InputDecoration(
                                hintText: 'Buscar por serviço, carro, valor...',
                                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
                                prefixIcon: Icon(Icons.search, color: secondaryTextColor, size: 20),
                                suffixIcon: _searchQuery.isNotEmpty
                                    ? IconButton(
                                        icon: Icon(Icons.close, color: secondaryTextColor, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          _safeSetState(() => _searchQuery = '');
                                        },
                                      )
                                    : null,
                                filled: true,
                                fillColor: themeService.isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: themeService.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(color: themeService.isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.08)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF00C977), width: 1.5),
                                ),
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
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: Center(
                          child: TextButton.icon(
                            onPressed: () => Navigator.pushNamed(context, '/financial-history'),
                            icon: const Icon(Icons.history, color: Color(0xFF00C977), size: 18),
                            label: const Text(
                              'Ver historico completo',
                              style: TextStyle(
                                color: Color(0xFF00C977),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        child: _buildAsaasSeal(themeService.isDarkMode),
                      ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 32)),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAsaasSeal(bool isDark) {
    final sealUrl = isDark
        ? 'https://baas.asaas.com/selos/Servicos_financeiros_Asaas-Reduzida-Negativo-Branco.svg?id=2a6ee772-f63f-424d-9d0e-1a3811b0f64c'
        : 'https://baas.asaas.com/selos/Servicos_financeiros_Asaas-Reduzida-Positivo.svg?id=2a6ee772-f63f-424d-9d0e-1a3811b0f64c';
    return Center(
      child: GestureDetector(
        onTap: () => launchUrl(Uri.parse(sealUrl), mode: LaunchMode.externalApplication),
        child: Opacity(
          opacity: 0.5,
          child: SvgPicture.network(
            sealUrl,
            height: 32,
            fit: BoxFit.contain,
            placeholderBuilder: (_) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }

  Widget _buildAnticipationCard({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    final s = _anticipationSummary;
    final totalAnticipated = s != null ? (s['total_anticipated'] ?? 0) : null;
    final pendingCount = s != null ? ((s['count_by_status'] as Map?)?['PENDING'] ?? 0) : null;
    final creditedCount = s != null ? ((s['count_by_status'] as Map?)?['CREDITED'] ?? 0) : null;

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/financial/anticipation'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor.withOpacity(0.4)),
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
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.flash_on_outlined,
                    color: Color(0xFF00C977),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Antecipacao de Recebiveis',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Receba antes do prazo previsto',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00C977),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF00C977)),
              ],
            ),
            if (s != null && (totalAnticipated is num && totalAnticipated > 0 || pendingCount is int && pendingCount > 0)) ...[
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF00C977).withOpacity(0.06),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (totalAnticipated is num && totalAnticipated > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total antecipado',
                              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                            ),
                            Text(
                              _currencyFormat.format(totalAnticipated),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF00C977)),
                            ),
                          ],
                        ),
                      ),
                    if (creditedCount is int && creditedCount > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'Creditadas',
                              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                            ),
                            Text(
                              '$creditedCount',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF60A5FA)),
                            ),
                          ],
                        ),
                      ),
                    if (pendingCount is int && pendingCount > 0)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Pendentes',
                              style: TextStyle(fontSize: 10, color: textColor.withOpacity(0.6)),
                            ),
                            Text(
                              '$pendingCount',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFF59E0B)),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
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
        'subtitle': 'Pagamentos aprovados, líquido de taxas',
      },
      {
        'title': 'Receita bruta',
        'value': totals['gross'],
        'icon': Icons.request_quote,
        'color': const Color(0xFF2563EB),
        'subtitle': 'Somatório dos pagamentos aprovados',
      },
    ];

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
      padding: const EdgeInsets.all(18),
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
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
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
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color: secondaryTextColor,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (trailing != null) ...[
            const SizedBox(height: 12),
            Divider(color: secondaryTextColor.withOpacity(0.2), height: 1),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    trailingLabel!,
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  trailing,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
        'value': _formatPercent(metrics['effective_meca_fee'] ?? 12, fallback: '12%'),
        'icon': Icons.percent,
        'color': const Color(0xFF8B5CF6),
      },
      {
        'title': 'A receber',
        'value': _buildPendingReceivable(totals),
        'icon': Icons.account_balance_wallet,
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                stat['icon'] as IconData,
                color: stat['color'] as Color,
                size: 24,
              ),
              const SizedBox(height: 10),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: secondaryTextColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Text(
                stat['value'] as String,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
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
    final allTransactions = (_financialData?['recent_transactions'] as List?)
            ?.cast<Map<String, dynamic>>() ??
        [];

    final transactions = _searchQuery.isEmpty
        ? allTransactions
        : allTransactions.where((t) {
            final service = (t['service_name'] ?? '').toString().toLowerCase();
            final vehicle = (t['vehicle_display'] ?? '').toString().toLowerCase();
            final method = (t['payment_method'] ?? '').toString().toLowerCase();
            final amount = _formatCurrency(t['gross_amount'], fallback: '').toLowerCase();
            return service.contains(_searchQuery) ||
                vehicle.contains(_searchQuery) ||
                method.contains(_searchQuery) ||
                amount.contains(_searchQuery);
          }).toList();

    if (allTransactions.isEmpty) {
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

    if (transactions.isEmpty && _searchQuery.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Icon(Icons.search_off, size: 48, color: secondaryTextColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Nenhuma transação encontrada',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              'Tente buscar por outro termo.',
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
    final rawMethod = (transaction['payment_method'] ?? '').toString().toUpperCase();
    final method = (rawMethod.isEmpty || rawMethod == 'UNDEFINED') ? 'Não informado' : rawMethod;
    final installments = transaction['installments'] ?? 1;
    final createdAt = _formatDate(transaction['created_at']);

    final netAmount = _formatCurrency(transaction['net_amount'], fallback: '—');
    final mecaFeeAmount = _formatCurrency(transaction['meca_fee_amount'], fallback: '—');
    final gatewayFeeAmount = _formatCurrency(transaction['gateway_fee_amount'] ?? transaction['pagbank_fee_amount'], fallback: '—');
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
              _buildAmountDetail('Tarifa financeira', gatewayFeeAmount, secondaryTextColor, textColor),
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

  String _buildPendingReceivable(Map<String, dynamic> totals) {
    final valuesToReceive = _toDouble(totals['values_to_receive']);
    final pendingGross = _toDouble(totals['pending_gross']);
    final net = _toDouble(totals['net']);

    final pending = (valuesToReceive ?? 0) + (pendingGross ?? 0);
    if (pending > 0) return _currencyFormat.format(pending);
    if (net != null && net > 0) return _currencyFormat.format(net);
    return 'R\$ 0,00';
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
    // API retorna 12 para 12% (já em percentual); se < 1 é decimal (0.12)
    final pct = parsed > 1 ? parsed : (parsed * 100);
    return '${pct.toStringAsFixed(0)}%';
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não informada';
    try {
      final dateTime = value is DateTime ? value : DateTime.parse(value.toString());
      final local = dateTime.toLocal();
      final day = local.day.toString().padLeft(2, '0');
      final month = local.month.toString().padLeft(2, '0');
      final year = local.year;
      final hour = local.hour.toString().padLeft(2, '0');
      final minute = local.minute.toString().padLeft(2, '0');
      return '$day/$month/$year às $hour:$minute';
    } catch (_) {
      return value.toString();
    }
  }
}