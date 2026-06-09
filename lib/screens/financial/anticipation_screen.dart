import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';

const _kGreen = Color(0xFF00C977);
const _kBgDark = Color(0xFF0A0A0A);
const _kCardDark = Color(0xFF1A1A1A);
const _kRed = Color(0xFFEF4444);
const _kAmber = Color(0xFFF59E0B);
const _kBlue = Color(0xFF60A5FA);

class AnticipationScreen extends StatefulWidget {
  const AnticipationScreen({Key? key}) : super(key: key);

  @override
  State<AnticipationScreen> createState() => _AnticipationScreenState();
}

class _AnticipationScreenState extends State<AnticipationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool _isLoading = true;
  bool _isSimulating = false;
  bool _isCreating = false;

  Map<String, dynamic>? _balance;
  List<Map<String, dynamic>> _anticipations = [];
  List<Map<String, dynamic>> _eligible = [];
  Map<String, dynamic>? _summary;
  String? _selectedPaymentId;
  Map<String, dynamic>? _simulation;
  String? _errorMessage;
  String _statusFilter = 'ALL';
  List<File> _selectedDocs = [];

  final ApiService _apiService = ApiService();
  final NumberFormat _currencyFormat =
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String? _workshopId;

  static const _feeTiers = [
    {'max': 30, 'rate': 1.25, 'label': 'ate 30 dias'},
    {'max': 60, 'rate': 2.50, 'label': '31-60 dias'},
    {'max': 90, 'rate': 3.75, 'label': '61-90 dias'},
    {'max': 180, 'rate': 5.00, 'label': '91-180 dias'},
    {'max': 99999, 'rate': 5.79, 'label': '180+ dias'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _init();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    await _apiService.loadToken();
    final id = await _apiService.getWorkshopId();
    if (!mounted) return;
    if (id == null || id.isEmpty) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Sessao invalida. Faca login novamente.';
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
      _selectedPaymentId = null;
      _selectedDocs = [];
    });

    try {
      final results = await Future.wait([
        _apiService.getAsaasBalance(_workshopId!),
        _apiService.listAnticipations(_workshopId!),
        _apiService.getEligiblePayments(_workshopId!),
        _apiService.getAnticipationSummary(_workshopId!),
      ]);

      final balanceRes = results[0];
      final anticipationsRes = results[1];
      final eligibleRes = results[2];
      final summaryRes = results[3];

      _safeSetState(() {
        if (balanceRes['success'] == true) {
          _balance = (balanceRes['data'] as Map?)?.cast<String, dynamic>();
        }

        _anticipations = _parseList(anticipationsRes['data'] ?? anticipationsRes);
        _eligible = _parseList(eligibleRes['data'] ?? eligibleRes);

        if (summaryRes['success'] == true && summaryRes['data'] is Map) {
          _summary = (summaryRes['data'] as Map).cast<String, dynamic>();
        }
      });
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao carregar dados: ${e.toString()}');
    } finally {
      _safeSetState(() => _isLoading = false);
    }
  }

  List<Map<String, dynamic>> _parseList(dynamic raw) {
    if (raw is List) {
      return raw.map((e) => (e as Map).cast<String, dynamic>()).toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();
    }
    return [];
  }

  Future<void> _simulate() async {
    if (_workshopId == null || _selectedPaymentId == null || _selectedPaymentId!.isEmpty) {
      _safeSetState(() => _errorMessage = 'Selecione uma cobranca para antecipar.');
      return;
    }
    _safeSetState(() {
      _isSimulating = true;
      _simulation = null;
      _errorMessage = null;
    });

    try {
      final res = await _apiService.simulateAnticipation(_workshopId!, {
        'payment': _selectedPaymentId,
      });
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
    if (_workshopId == null || _simulation == null || _selectedPaymentId == null) return;

    final docRequired = _simulation?['isDocumentationRequired'] == true;
    if (docRequired && _selectedDocs.isEmpty) {
      _safeSetState(() => _errorMessage =
          'Documentacao obrigatoria. Anexe NF-e ou contrato antes de confirmar.');
      return;
    }

    final ok = await _showConfirmDialog();
    if (!ok || !mounted) return;

    _safeSetState(() {
      _isCreating = true;
      _errorMessage = null;
    });

    try {
      final selectedPayment = _eligible.firstWhere(
        (p) => (p['payment_id'] ?? p['id']).toString() == _selectedPaymentId,
        orElse: () => <String, dynamic>{},
      );

      final res = await _apiService.createAnticipation(
        _workshopId!,
        {
          'payment': _selectedPaymentId,
          'grossAmount': selectedPayment['value']?.toString(),
          'dueDate': selectedPayment['due_date']?.toString(),
        },
        documents: _selectedDocs.isNotEmpty ? _selectedDocs : null,
      );

      if (!mounted) return;
      if (res['success'] == true) {
        _safeSetState(() {
          _simulation = null;
          _selectedPaymentId = null;
          _selectedDocs = [];
        });
        _showSuccessSnack('Antecipacao solicitada com sucesso!');
        await _loadData();
      } else {
        _safeSetState(() =>
            _errorMessage = res['error']?.toString() ?? 'Erro ao criar antecipacao');
      }
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao criar antecipacao: ${e.toString()}');
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
        _showSuccessSnack('Antecipacao cancelada.');
        await _loadData();
      } else {
        _safeSetState(() => _errorMessage = res['error']?.toString() ?? 'Erro ao cancelar');
      }
    } catch (e) {
      _safeSetState(() => _errorMessage = 'Erro ao cancelar: ${e.toString()}');
    }
  }

  Future<void> _pickDocuments() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'xml', 'png', 'jpg', 'jpeg'],
      allowMultiple: true,
    );
    if (result != null && result.files.isNotEmpty) {
      _safeSetState(() {
        _selectedDocs = result.files
            .where((f) => f.path != null)
            .map((f) => File(f.path!))
            .toList();
      });
    }
  }

  String _feeTierLabel(dynamic dueDate) {
    if (dueDate == null) return '';
    try {
      final due = DateTime.parse(dueDate.toString());
      final days = due.difference(DateTime.now()).inDays;
      for (final tier in _feeTiers) {
        if (days <= (tier['max'] as int)) {
          return '${tier['rate']}% a.m. (${tier['label']})';
        }
      }
    } catch (_) {}
    return '';
  }

  Color _feeTierColor(dynamic dueDate) {
    if (dueDate == null) return _kGreen;
    try {
      final due = DateTime.parse(dueDate.toString());
      final days = due.difference(DateTime.now()).inDays;
      if (days <= 30) return _kGreen;
      if (days <= 60) return const Color(0xFF34D399);
      if (days <= 90) return _kAmber;
      if (days <= 180) return const Color(0xFFF97316);
      return _kRed;
    } catch (_) {
      return _kGreen;
    }
  }

  Future<bool> _showConfirmDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar antecipacao'),
        content: const Text(
          'Deseja confirmar a solicitacao de antecipacao? Os valores e taxas da simulacao serao aplicados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kGreen,
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
        title: const Text('Cancelar antecipacao'),
        content: const Text('Deseja cancelar esta solicitacao de antecipacao?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Voltar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Cancelar antecipacao'),
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
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredAnticipations {
    if (_statusFilter == 'ALL') return _anticipations;
    return _anticipations
        .where((a) => (a['status'] ?? '').toString().toUpperCase() == _statusFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeService>(
      builder: (context, themeService, _) {
        final isDark = themeService.isDarkMode;
        final bgColor = isDark ? _kBgDark : const Color(0xFFF5F7FA);
        final textColor = isDark ? const Color(0xFFF9FAFB) : const Color(0xFF111827);
        final secondaryTextColor = isDark ? const Color(0xFFD1D5DB) : const Color(0xFF6B7280);
        final cardColor = isDark ? _kCardDark : Colors.white;
        final borderColor = isDark ? const Color(0xFF065F46) : _kGreen;

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
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor),
            ),
            bottom: TabBar(
              controller: _tabController,
              labelColor: _kGreen,
              unselectedLabelColor: secondaryTextColor,
              indicatorColor: _kGreen,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              tabs: const [
                Tab(text: 'Disponiveis'),
                Tab(text: 'Historico'),
              ],
            ),
          ),
          body: _isLoading
              ? AnimationWidgets.buildLoadingWidget(message: 'Carregando dados...')
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEligibleTab(
                      bgColor: bgColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                    _buildHistoryTab(
                      bgColor: bgColor,
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  ],
                ),
        );
      },
    );
  }

  // ── Tab: Disponiveis ─────────────────────────────────────────────

  Widget _buildEligibleTab({
    required Color bgColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_errorMessage != null) _buildErrorBanner(_errorMessage!),
                  _buildBalanceCard(cardColor: cardColor, borderColor: borderColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                  const SizedBox(height: 16),
                  if (_summary != null) _buildSummaryCards(textColor: textColor, secondaryTextColor: secondaryTextColor, cardColor: cardColor),
                  const SizedBox(height: 16),
                  _buildFeeTierInfo(cardColor: cardColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                  const SizedBox(height: 16),
                  Text('Selecione uma cobranca', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 4),
                  Text('Cobranças confirmadas elegiveis para antecipacao.', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
                  const SizedBox(height: 12),
                  if (_eligible.isEmpty) _buildEmptyState(icon: Icons.info_outline, title: 'Nenhuma cobranca disponivel', subtitle: 'Cobranças confirmadas aparecerao aqui.', cardColor: cardColor, borderColor: borderColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                  if (_eligible.isNotEmpty) ...[
                    _buildPaymentSelector(cardColor: cardColor, borderColor: borderColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                    const SizedBox(height: 16),
                    if (_simulation != null) ...[
                      _buildSimulationResult(cardColor: cardColor, borderColor: borderColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                      if (_simulation?['isDocumentationRequired'] == true)
                        _buildDocUploadSection(cardColor: cardColor, textColor: textColor, secondaryTextColor: secondaryTextColor),
                    ],
                    if (_simulation == null)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: (_isSimulating || _selectedPaymentId == null) ? null : _simulate,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kGreen,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _kGreen.withOpacity(0.4),
                            disabledForegroundColor: Colors.white.withOpacity(0.6),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          icon: _isSimulating
                              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                              : const Icon(Icons.calculate_outlined),
                          label: Text(_isSimulating ? 'Simulando...' : 'Simular antecipacao', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        ),
                      ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Tab: Historico ───────────────────────────────────────────────

  Widget _buildHistoryTab({
    required Color bgColor,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final filtered = _filteredAnticipations;

    return RefreshIndicator(
      onRefresh: _loadData,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Historico de Antecipacoes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                  const SizedBox(height: 12),
                  _buildStatusFilter(secondaryTextColor),
                  const SizedBox(height: 16),
                  if (filtered.isEmpty)
                    _buildEmptyState(
                      icon: Icons.inbox_outlined,
                      title: 'Nenhuma solicitacao encontrada',
                      subtitle: _statusFilter == 'ALL'
                          ? 'Suas solicitacoes de antecipacao aparecerao aqui.'
                          : 'Nenhuma antecipacao com este status.',
                      cardColor: cardColor,
                      borderColor: borderColor,
                      textColor: textColor,
                      secondaryTextColor: secondaryTextColor,
                    ),
                  if (filtered.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => Divider(height: 1, color: secondaryTextColor.withOpacity(0.15)),
                        itemBuilder: (context, index) => _buildAnticipationItem(
                          filtered[index],
                          textColor: textColor,
                          secondaryTextColor: secondaryTextColor,
                        ),
                      ),
                    ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Summary KPI cards ────────────────────────────────────────────

  Widget _buildSummaryCards({
    required Color textColor,
    required Color secondaryTextColor,
    required Color cardColor,
  }) {
    final s = _summary!;
    final totalAnticipated = _toDouble(s['total_anticipated']) ?? 0;
    final totalFees = _toDouble(s['total_fees_paid']) ?? 0;
    final countCredited = (s['count_by_status'] as Map?)?['CREDITED'] ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            label: 'Total antecipado',
            value: _formatCurrency(totalAnticipated),
            icon: Icons.trending_up,
            color: _kGreen,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            label: 'Taxas pagas',
            value: _formatCurrency(totalFees),
            icon: Icons.receipt_outlined,
            color: _kAmber,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            label: 'Creditadas',
            value: '$countCredited',
            icon: Icons.check_circle_outline,
            color: _kBlue,
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            cardColor: cardColor,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required Color textColor,
    required Color secondaryTextColor,
    required Color cardColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 10, color: secondaryTextColor), maxLines: 1),
        ],
      ),
    );
  }

  // ── Fee tier info ────────────────────────────────────────────────

  Widget _buildFeeTierInfo({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: secondaryTextColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: secondaryTextColor),
              const SizedBox(width: 6),
              Text('Taxas por prazo', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
            ],
          ),
          const SizedBox(height: 10),
          ..._feeTiers.map((tier) {
            final rate = tier['rate'] as double;
            final label = tier['label'] as String;
            Color c;
            if (rate <= 1.25) {
              c = _kGreen;
            } else if (rate <= 2.50) {
              c = const Color(0xFF34D399);
            } else if (rate <= 3.75) {
              c = _kAmber;
            } else if (rate <= 5.0) {
              c = const Color(0xFFF97316);
            } else {
              c = _kRed;
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text('$label', style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                  const Spacer(),
                  Text('${rate.toStringAsFixed(2)}% a.m.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: c)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── Status filter chips ──────────────────────────────────────────

  Widget _buildStatusFilter(Color secondaryTextColor) {
    final options = ['ALL', 'PENDING', 'CREDITED', 'DENIED', 'CANCELLED', 'SCHEDULED'];
    final labels = {'ALL': 'Todas', 'PENDING': 'Pendentes', 'CREDITED': 'Creditadas', 'DENIED': 'Negadas', 'CANCELLED': 'Canceladas', 'SCHEDULED': 'Agendadas'};

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((opt) {
          final isActive = _statusFilter == opt;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(labels[opt] ?? opt),
              selected: isActive,
              selectedColor: _kGreen.withOpacity(0.15),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? _kGreen : secondaryTextColor,
              ),
              side: BorderSide(color: isActive ? _kGreen : secondaryTextColor.withOpacity(0.3)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              onSelected: (_) => _safeSetState(() => _statusFilter = opt),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Doc upload section ───────────────────────────────────────────

  Widget _buildDocUploadSection({
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _kAmber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kAmber.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: _kAmber, size: 20),
              const SizedBox(width: 8),
              Text('Documentacao obrigatoria', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
          const SizedBox(height: 8),
          Text('Anexe a NF-e ou contrato de prestacao de servico.', style: TextStyle(fontSize: 13, color: secondaryTextColor)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickDocuments,
            icon: const Icon(Icons.attach_file, size: 18),
            label: Text(_selectedDocs.isEmpty ? 'Selecionar arquivo' : '${_selectedDocs.length} arquivo(s) selecionado(s)'),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kAmber,
              side: const BorderSide(color: _kAmber),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
          if (_selectedDocs.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._selectedDocs.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  const Icon(Icons.description, size: 14, color: _kAmber),
                  const SizedBox(width: 6),
                  Expanded(child: Text(f.path.split('/').last, style: TextStyle(fontSize: 12, color: secondaryTextColor), overflow: TextOverflow.ellipsis)),
                  GestureDetector(
                    onTap: () => _safeSetState(() => _selectedDocs.remove(f)),
                    child: const Icon(Icons.close, size: 14, color: _kRed),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  // ── Shared widgets ───────────────────────────────────────────────

  Widget _buildErrorBanner(String message) {
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
          Expanded(child: Text(message, style: const TextStyle(fontSize: 13, color: Color(0xFFB91C1C), fontWeight: FontWeight.w500))),
          GestureDetector(
            onTap: () => _safeSetState(() => _errorMessage = null),
            child: const Icon(Icons.close, size: 16, color: Color(0xFFB91C1C)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: secondaryTextColor),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: textColor)),
          const SizedBox(height: 8),
          Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
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

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [BoxShadow(color: _kGreen.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, 6))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: _kGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.account_balance_wallet, color: _kGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Text('Saldo Asaas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
          const SizedBox(height: 20),
          _buildBalanceRow(label: 'Saldo disponivel', value: available, textColor: textColor, secondaryTextColor: secondaryTextColor, highlight: true),
          if (pending != null) ...[
            const SizedBox(height: 12),
            _buildBalanceRow(label: 'Saldo a receber', value: pending, textColor: textColor, secondaryTextColor: secondaryTextColor),
          ],
        ],
      ),
    );
  }

  Widget _buildBalanceRow({required String label, required dynamic value, required Color textColor, required Color secondaryTextColor, bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
        Text(_formatCurrency(value), style: TextStyle(fontSize: highlight ? 22 : 15, fontWeight: highlight ? FontWeight.w700 : FontWeight.w600, color: highlight ? _kGreen : textColor)),
      ],
    );
  }

  Widget _buildPaymentSelector({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Icon(Icons.receipt_long, size: 18, color: secondaryTextColor),
                const SizedBox(width: 8),
                Text('${_eligible.length} cobranca(s) disponivel(is)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: secondaryTextColor)),
              ],
            ),
          ),
          ..._eligible.map((payment) {
            final payId = (payment['payment_id'] ?? payment['id'] ?? '').toString();
            final isSelected = _selectedPaymentId == payId;
            final value = payment['value'] ?? payment['netValue'];
            final customer = payment['customer_name'] ?? payment['customerName'] ?? '';
            final dueDate = payment['due_date'] ?? payment['dueDate'];
            final dueDateStr = _formatDateShort(dueDate);
            final tierLabel = _feeTierLabel(dueDate);
            final tierColor = _feeTierColor(dueDate);
            final estNet = payment['estimated_net_amount'];

            return InkWell(
              onTap: () {
                _safeSetState(() {
                  _selectedPaymentId = isSelected ? null : payId;
                  _simulation = null;
                  _selectedDocs = [];
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? _kGreen.withOpacity(0.08) : Colors.transparent,
                  border: Border(top: BorderSide(color: secondaryTextColor.withOpacity(0.1))),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 22, height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? _kGreen : Colors.transparent,
                        border: Border.all(color: isSelected ? _kGreen : secondaryTextColor.withOpacity(0.4), width: 2),
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(_formatCurrency(value), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                              if (estNet != null) ...[
                                const SizedBox(width: 6),
                                Text('(liq. ${_formatCurrency(estNet)})', style: TextStyle(fontSize: 11, color: _kGreen)),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            customer.toString().isNotEmpty ? '$customer • $dueDateStr' : dueDateStr,
                            style: TextStyle(fontSize: 12, color: secondaryTextColor),
                          ),
                          if (tierLabel.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(tierLabel, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: tierColor)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildSimulationResult({
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
  }) {
    final sim = _simulation!;
    final grossValue = sim['totalGrossValue'] ?? sim['gross_value'] ?? sim['value'] ?? sim['anticipatedValue'];
    final netValue = sim['totalNetValue'] ?? sim['net_value'] ?? sim['netValue'];
    final fee = sim['anticipationFee'] ?? sim['fee'] ?? sim['totalFee'];
    final docRequired = sim['isDocumentationRequired'] == true;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _kGreen.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGreen.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle_outline, color: _kGreen, size: 22),
              const SizedBox(width: 8),
              Text('Simulacao de antecipacao', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
            ],
          ),
          const SizedBox(height: 16),
          _buildSimRow(label: 'Valor bruto', value: _formatCurrency(grossValue), textColor: textColor, secondaryTextColor: secondaryTextColor),
          if (fee != null) ...[
            const SizedBox(height: 10),
            _buildSimRow(label: 'Taxa de antecipacao', value: '- ${_formatCurrency(fee)}', textColor: _kRed, secondaryTextColor: secondaryTextColor),
          ],
          if (docRequired) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded, size: 16, color: _kAmber),
                const SizedBox(width: 6),
                Text('Documentacao obrigatoria', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _kAmber)),
              ],
            ),
          ],
          const SizedBox(height: 14),
          const Divider(height: 1, color: _kGreen),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Valor liquido a receber', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: textColor)),
              Text(_formatCurrency(netValue), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: _kGreen)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _safeSetState(() {
                    _simulation = null;
                    _selectedDocs = [];
                  }),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: secondaryTextColor,
                    side: BorderSide(color: secondaryTextColor.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isCreating ? null : _confirm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: _isCreating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimRow({required String label, required String value, required Color textColor, required Color secondaryTextColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontSize: 14, color: secondaryTextColor)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
      ],
    );
  }

  Widget _buildAnticipationItem(Map<String, dynamic> item, {required Color textColor, required Color secondaryTextColor}) {
    final status = (item['status'] ?? '').toString().toUpperCase();
    final id = (item['asaas_anticipation_id'] ?? item['id'] ?? item['anticipationId'] ?? '').toString();
    final totalValue = item['gross_amount'] ?? item['totalValue'] ?? item['value'] ?? item['grossValue'];
    final netValue = item['net_amount'] ?? item['totalNetValue'] ?? item['netValue'] ?? item['net_value'];
    final feeAmount = item['fee_amount'] ?? item['fee'];
    final createdAt = _formatDate(item['requested_at'] ?? item['dateCreated'] ?? item['created_at']);
    final canCancel = status == 'PENDING';

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
                    Text(createdAt, style: TextStyle(fontSize: 12, color: secondaryTextColor)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(_formatCurrency(totalValue), style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
                  if (netValue != null) ...[
                    const SizedBox(height: 2),
                    Text('Liq: ${_formatCurrency(netValue)}', style: TextStyle(fontSize: 12, color: _kGreen)),
                  ],
                  if (feeAmount != null) ...[
                    const SizedBox(height: 2),
                    Text('Taxa: ${_formatCurrency(feeAmount)}', style: TextStyle(fontSize: 11, color: secondaryTextColor)),
                  ],
                ],
              ),
            ],
          ),
          if (canCancel) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () => _cancel(id),
              style: TextButton.styleFrom(foregroundColor: _kRed, padding: EdgeInsets.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              icon: const Icon(Icons.cancel_outlined, size: 16),
              label: const Text('Cancelar solicitacao', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
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
      case 'CREDITED':
        bg = const Color(0xFFDCFCE7);
        fg = const Color(0xFF15803D);
        label = 'Creditada';
        break;
      case 'PENDING':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFB45309);
        label = 'Pendente';
        break;
      case 'SCHEDULED':
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = 'Agendada';
        break;
      case 'DENIED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Negada';
        break;
      case 'CANCELLED':
        bg = const Color(0xFFF3F4F6);
        fg = const Color(0xFF6B7280);
        label = 'Cancelada';
        break;
      case 'OVERDUE':
        bg = const Color(0xFFFFF7ED);
        fg = const Color(0xFFF97316);
        label = 'Vencida';
        break;
      case 'DEBITED':
        bg = const Color(0xFFFEE2E2);
        fg = const Color(0xFFB91C1C);
        label = 'Debitada';
        break;
      default:
        bg = const Color(0xFFEFF6FF);
        fg = const Color(0xFF1D4ED8);
        label = status;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }

  // ── Formatters ───────────────────────────────────────────────────

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.replaceAll(RegExp(r'[^0-9,.-]'), '').replaceAll(',', '.');
      return double.tryParse(normalized);
    }
    return null;
  }

  String _formatCurrency(dynamic value) {
    final parsed = _toDouble(value);
    if (parsed == null) return 'R\$ 0,00';
    return _currencyFormat.format(parsed);
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

  String _formatDateShort(dynamic value) {
    if (value == null) return '';
    try {
      final dt = value is DateTime ? value : DateTime.parse(value.toString());
      return DateFormat('dd/MM/yyyy').format(dt.toLocal());
    } catch (_) {
      return value.toString();
    }
  }
}
