import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../utils/form_styles.dart';
import '../../utils/date_formatter.dart';
import '../../core/app_colors.dart';
import 'package:intl/intl.dart';

import '../bookings/booking_detail_screen.dart' show BookingDetailScreen;
import '../pre_compra/pre_compra_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _pendingBookings = [];
  List<Map<String, dynamic>> _confirmedBookings = [];
  List<Map<String, dynamic>> _completedBookings = [];
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _safeSetState(() {});
    }
  }

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    setState(fn);
  }

  Widget _buildStatusTab(
    String title,
    int count,
    IconData icon,
    Color color,
    bool isSelected,
    VoidCallback onTap,
    bool isDark,
  ) {
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(isDark ? 0.28 : 0.9)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? color.withOpacity(0.6) : ThemeService.getBorderColor(isDark).withOpacity(0.4),
            width: isSelected ? 1.4 : 1,
          ),
          boxShadow: isSelected && !isDark
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ]
              : [],
        ),
        child: Semantics(
          label: '$title: $count agendamentos',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? Colors.white : secondaryTextColor,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                softWrap: false,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected ? Colors.white : textColor,
                ),
              ),
              const SizedBox(height: 4),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected ? Colors.white.withOpacity(0.9) : secondaryTextColor,
                ),
                child: Text('$count'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Carrega agendamentos do servidor (fonte única de verdade).
  /// [forceRefresh] bypassa cache após mutação — reject, confirm, suggest.
  Future<void> _loadBookings({bool forceRefresh = false}) async {
    if (!mounted) return;
    _safeSetState(() => _isLoading = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (mounted) Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();

      // Buscar bookings normais (por status) e pré-compras em paralelo
      final responses = await Future.wait([
        _apiService.getMyBookings(status: 'pendente_oficina', forceRefresh: forceRefresh),
        _apiService.getMyBookings(status: 'confirmado', forceRefresh: forceRefresh),
        _apiService.getMyBookings(status: 'concluido', forceRefresh: forceRefresh),
        _apiService.getWorkshopPreCompras(),
      ]);

      if (!mounted) return;

      final pendingResponse = responses[0];
      final confirmedResponse = responses[1];
      final completedResponse = responses[2];
      final preCompraResponse = responses[3];

      // Normalizar pré-compras e distribuir nas listas
      final List<Map<String, dynamic>> preCompras = preCompraResponse['success'] == true
          ? (preCompraResponse['data'] as List? ?? []).cast<Map<String, dynamic>>()
          : [];

      final pendingPreCompras = preCompras
          .where((p) => (p['status'] ?? '') == 'pendente')
          .toList();
      final confirmedPreCompras = preCompras
          .where((p) => ['confirmado', 'em_andamento', 'aguardando_pagamento'].contains(p['status'] ?? ''))
          .toList();
      final completedPreCompras = preCompras
          .where((p) => ['concluido', 'concluído', 'cancelado'].contains(p['status'] ?? ''))
          .toList();

      _safeSetState(() {
        if (pendingResponse['success'] == true) {
          _pendingBookings = [
            ...List<Map<String, dynamic>>.from(pendingResponse['data']?['bookings'] ?? []),
            ...pendingPreCompras,
          ];
        }
        if (confirmedResponse['success'] == true) {
          _confirmedBookings = [
            ...List<Map<String, dynamic>>.from(confirmedResponse['data']?['bookings'] ?? []),
            ...confirmedPreCompras,
          ];
        }
        if (completedResponse['success'] == true) {
          _completedBookings = [
            ...List<Map<String, dynamic>>.from(completedResponse['data']?['bookings'] ?? []),
            ...completedPreCompras,
          ];
        }
      });
    } catch (e) {
      // Erro silencioso — manter dados atuais
    } finally {
      if (mounted) _safeSetState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final bgColor = themeService.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
    final textColor = themeService.isDarkMode ? Colors.white : const Color(0xFF111827);
    
    final secondaryText = ThemeService.getSecondaryTextColor(themeService.isDarkMode);
    
    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Agenda',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Visualize e controle seus agendamentos em tempo real.',
                    style: TextStyle(
                      fontSize: 15,
                      color: secondaryText,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildStatusToolbar(themeService.isDarkMode),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? AnimationWidgets.buildLoadingWidget(message: 'Carregando agenda...')
                  : TabBarView(
                      controller: _tabController,
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildBookingsList(_pendingBookings, 'pending'),
                        _buildConfirmedBookingsList(), // Separar confirmados atuais e antigos
                        _buildBookingsList(_completedBookings, 'completed'),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusToolbar(bool isDark) {
    final items = [
      {
        'title': 'Pendentes',
        'count': _pendingBookings.length,
        'icon': Icons.pending_actions,
        'color': const Color(0xFFF97316),
      },
      {
        'title': 'Confirmados',
        'count': _confirmedBookings.length,
        'icon': Icons.check_circle_outline,
        'color': const Color(0xFF22C55E),
      },
      {
        'title': 'Concluídos',
        'count': _completedBookings.length,
        'icon': Icons.done_all,
        'color': const Color(0xFF6B7280),
      },
    ];

    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);

    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor.withOpacity(0.6), width: 1.2),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
      ),
      child: Row(
        children: List.generate(items.length, (index) {
          final item = items[index];
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _buildStatusTab(
                item['title'] as String,
                item['count'] as int,
                item['icon'] as IconData,
                item['color'] as Color,
                _tabController.index == index,
                () => _tabController.animateTo(index),
                isDark,
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, String type) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon(type),
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage(type),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeService.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(type),
              style: TextStyle(
                fontSize: 14,
                color: ThemeService.getSecondaryTextColor(isDark),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _loadBookings(forceRefresh: true),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return booking['booking_type'] == 'pre_compra'
              ? _buildPreCompraCard(booking)
              : _buildBookingCard(booking, type);
        },
      ),
    );
  }

  // Separar agendamentos confirmados em atuais e antigos
  Widget _buildConfirmedBookingsList() {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    // Separar por data
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    final currentBookings = <Map<String, dynamic>>[];
    final pastBookings = <Map<String, dynamic>>[];
    
    for (final booking in _confirmedBookings) {
      try {
        final appointmentDate = booking['appointment_date'];
        if (appointmentDate != null) {
          final date = DateTime.parse(appointmentDate);
          final bookingDate = DateTime(date.year, date.month, date.day);

          if (bookingDate.isBefore(today)) {
            pastBookings.add(booking);
          } else {
            currentBookings.add(booking);
          }
        } else {
          // Se não tiver data, considerar como atual
          currentBookings.add(booking);
        }
      } catch (e) {
        // Se houver erro ao parsear data, considerar como atual
        currentBookings.add(booking);
      }
    }
    
    if (currentBookings.isEmpty && pastBookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getEmptyIcon('confirmed'),
              size: 64,
              color: const Color(0xFFD1D5DB),
            ),
            const SizedBox(height: 16),
            Text(
              _getEmptyMessage('confirmed'),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: ThemeService.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle('confirmed'),
              style: TextStyle(
                fontSize: 14,
                color: ThemeService.getSecondaryTextColor(isDark),
              ),
            ),
          ],
        ),
      );
    }
    
    return RefreshIndicator(
      onRefresh: () => _loadBookings(forceRefresh: true),
      child: CustomScrollView(
        slivers: [
          // Agendamentos atuais
          if (currentBookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agendamentos Confirmados',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: ThemeService.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Clique no card do serviço para ver o status e ver o que deve fazer',
                      style: TextStyle(
                        fontSize: 13,
                        color: ThemeService.getSecondaryTextColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = currentBookings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: item['booking_type'] == 'pre_compra'
                        ? _buildPreCompraCard(item)
                        : _buildBookingCard(item, 'confirmed'),
                  );
                },
                childCount: currentBookings.length,
              ),
            ),
          ],

          // Separador para agendamentos antigos
          if (pastBookings.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.fromLTRB(20, 28, 20, 12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isDark
                          ? [
                              Colors.orange.shade900.withOpacity(0.3),
                              Colors.orange.shade800.withOpacity(0.2),
                            ]
                          : [
                              Colors.orange.shade50,
                              Colors.orange.shade100.withOpacity(0.5),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark
                          ? Colors.orange.shade700.withOpacity(0.3)
                          : Colors.orange.shade200.withOpacity(0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.orange.shade200.withOpacity(isDark ? 0.1 : 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                        spreadRadius: 0,
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                        spreadRadius: -2,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Ícone com background circular
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.orange.shade400,
                              Colors.orange.shade600,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.orange.shade400.withOpacity(0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.history_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Texto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Agendamentos Anteriores',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isDark
                                    ? Colors.orange.shade200
                                    : Colors.orange.shade900,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Datas anteriores ao dia atual',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark
                                    ? Colors.orange.shade300.withOpacity(0.8)
                                    : Colors.orange.shade700.withOpacity(0.8),
                                letterSpacing: -0.2,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = pastBookings[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: item['booking_type'] == 'pre_compra'
                        ? _buildPreCompraCard(item)
                        : _buildBookingCard(item, 'confirmed'),
                  );
                },
                childCount: pastBookings.length,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getEmptyIcon(String type) {
    switch (type) {
      case 'pending':
        return Icons.pending_actions;
      case 'confirmed':
        return Icons.schedule;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.calendar_today;
    }
  }

  String _getEmptyMessage(String type) {
    switch (type) {
      case 'pending':
        return 'Nenhum agendamento pendente';
      case 'confirmed':
        return 'Nenhum agendamento confirmado';
      case 'completed':
        return 'Nenhum agendamento concluído';
      default:
        return 'Nenhum agendamento';
    }
  }

  String _getEmptySubtitle(String type) {
    switch (type) {
      case 'pending':
        return 'Novos agendamentos aparecerão aqui';
      case 'confirmed':
        return 'Agendamentos confirmados aparecerão aqui';
      case 'completed':
        return 'Agendamentos concluídos aparecerão aqui';
      default:
        return 'Seus agendamentos aparecerão aqui';
    }
  }

  Widget _buildPreCompraCard(Map<String, dynamic> item) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final status = (item['status'] ?? 'pendente').toString();
    final brand = (item['vehicle_brand'] ?? '').toString();
    final model = (item['vehicle_model'] ?? '').toString();
    final year = (item['vehicle_year'] ?? '').toString();
    final vehicleDesc = [brand, model, year].where((s) => s.isNotEmpty).join(' ');
    final customerName = (item['customer_name'] ?? 'Cliente').toString();

    String dateStr = 'Data não definida';
    final rawDate = item['inspection_date'] ?? item['created_at'];
    if (rawDate != null) {
      try {
        final parsed = DateTime.parse(rawDate.toString());
        final prefix = item['inspection_date'] != null ? '' : 'Solicitado em ';
        dateStr = '$prefix${DateFormat('dd/MM/yyyy').format(parsed)}';
      } catch (_) {}
    }

    return InkWell(
      onTap: () async {
        final id = item['id']?.toString() ?? '';
        if (id.isNotEmpty) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PreCompraDetailOfinaScreen(preCompraId: id),
            ),
          );
          _loadBookings(forceRefresh: true);
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: ThemeService.getCardColor(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: ThemeService.getBorderColor(isDark), width: 1),
          boxShadow: isDark
              ? []
              : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00C977).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.search_rounded, color: Color(0xFF00C977), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicleDesc.isNotEmpty ? vehicleDesc : 'Veículo a inspecionar',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: ThemeService.getTextColor(isDark),
                        ),
                      ),
                      Text(
                        customerName,
                        style: TextStyle(fontSize: 14, color: ThemeService.getSecondaryTextColor(isDark)),
                      ),
                    ],
                  ),
                ),
                // Badges
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFF00C977).withOpacity(0.35)),
                      ),
                      child: const Text(
                        'Pré-Compra',
                        style: TextStyle(
                          color: Color(0xFF00C977),
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _getStatusText(status),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: ThemeService.getSecondaryTextColor(isDark)),
                const SizedBox(width: 6),
                Text(dateStr, style: TextStyle(fontSize: 13, color: ThemeService.getSecondaryTextColor(isDark))),
              ],
            ),
            if (status == 'pendente') ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _confirmPreCompra(item),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Aprovar', overflow: TextOverflow.ellipsis, maxLines: 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF10B981),
                        side: const BorderSide(color: Color(0xFF10B981)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _cancelPreCompra(item),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Recusar', overflow: TextOverflow.ellipsis, maxLines: 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _suggestNewTimePreCompra(item),
                      icon: const Icon(Icons.schedule, size: 16),
                      label: const Text('Sugerir', overflow: TextOverflow.ellipsis, maxLines: 1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: const BorderSide(color: Color(0xFFF59E0B)),
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking, String type) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return InkWell(
      onTap: () async {
        final navResult = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        );
        if (mounted) {
          await _loadBookings(forceRefresh: true);
          if (navResult == 'approved' && mounted) {
            _tabController.index = 1;
            _safeSetState(() {});
          }
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: ThemeService.getBorderColor(isDark),
          width: 1,
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _getStatusColor(booking['status']).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.car_repair,
                  color: _getStatusColor(booking['status']),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      booking['service_name'] ?? 'Serviço',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: ThemeService.getTextColor(isDark),
                      ),
                    ),
                    Text(
                      booking['customer_name'] ?? 'Cliente',
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeService.getSecondaryTextColor(isDark),
                      ),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking['status']).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _getStatusText(booking['status']),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _getStatusColor(booking['status']),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Vehicle info
          if (booking['vehicle_snapshot'] != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: ThemeService.getInputColor(isDark),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.directions_car,
                    size: 16,
                    color: ThemeService.getSecondaryTextColor(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking['vehicle_snapshot']['marca']} ${booking['vehicle_snapshot']['modelo']} - ${booking['vehicle_snapshot']['placa']}',
                    style: TextStyle(
                      fontSize: 14,
                      color: ThemeService.getSecondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          
          // Date and time
          Row(
            children: [
              const Icon(
                Icons.access_time,
                size: 16,
                color: Color(0xFF00C977),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(booking['appointment_date']),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const Spacer(),
              if (booking['estimated_price'] != null)
                Text(
                  'R\$ ${(booking['estimated_price'] / 100).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                      color: ThemeService.getTextColor(isDark),
                  ),
                ),
            ],
          ),
          
          // Customer notes
          if (booking['customer_notes'] != null && booking['customer_notes'].isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7).withOpacity(isDark ? 0.1 : 1.0),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFF59E0B).withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.note,
                    size: 16,
                    color: Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      booking['customer_notes'],
                      style: TextStyle(
                        fontSize: 14,
                        color: ThemeService.getTextColor(isDark),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          // Actions for pending bookings
          if (type == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _confirmBooking(booking),
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Aprovar', overflow: TextOverflow.ellipsis, maxLines: 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBooking(booking),
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Recusar', overflow: TextOverflow.ellipsis, maxLines: 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _suggestNewTime(booking),
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Sugerir', overflow: TextOverflow.ellipsis, maxLines: 1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
        ),
      ),
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'pendente_oficina':
        return const Color(0xFFF59E0B);
      case 'confirmado':
        return const Color(0xFF10B981);
      case 'aguardando_pagamento':
        return const Color(0xFFF59E0B); // amber — ação pendente (pagamento)
      case 'concluido':
        return const Color(0xFF6B7280);
      case 'cancelado':
      case 'recusado':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getStatusText(String? status) {
    final normalized = (status ?? '').toLowerCase();
    switch (normalized) {
      case 'pendente_oficina':
      case 'pending':
      case 'pendente':
        return 'Pendente';
      case 'confirmado':
      case 'confirmed':
        return 'Confirmado';
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
      case 'started':
        return 'Em Andamento';
      case 'concluido':
      case 'concluído':
      case 'completed':
        return 'Concluído';
      case 'cancelado':
      case 'cancelled':
        return 'Cancelado';
      case 'recusado':
        return 'Recusado';
      case 'aguardando_pagamento':
      case 'finalizado_aguardando_pagamento':
      case 'finalizado':
      case 'awaiting_payment':
        return 'Aguardando Pagamento';
      case 'pago':
      case 'paid':
        return 'Pago';
      default:
        return status ?? 'Desconhecido';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Data não informada';
    try {
      final date = DateTime.parse(dateTime);
      return humanizeBookingDate(date);
    } catch (e) {
      return dateTime;
    }
  }

  Future<void> _confirmBooking(Map<String, dynamic> booking) async {
    try {
      final result = await _apiService.confirmBooking(booking['id']);
      if (result['success']) {
        final id = booking['id']?.toString();
        if (id != null && id.isNotEmpty) {
          _safeSetState(() {
            _pendingBookings.removeWhere((b) => b['id']?.toString() == id);
            final updated = Map<String, dynamic>.from(booking);
            updated['status'] = 'confirmado';
            _confirmedBookings.insert(0, updated);
          });
        }
        if (mounted) {
          _tabController.index = 1;
          _safeSetState(() {});
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento aprovado! Movido para Confirmados.'),
              backgroundColor: Color(0xFF00C977),
              duration: Duration(seconds: 3),
            ),
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted) _loadBookings(forceRefresh: true);
          });
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${result['error']}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    }
  }

  Future<void> _rejectBooking(Map<String, dynamic> booking) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);
    
    final reasonController = TextEditingController();
    
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header com ícone
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.cancel_outlined,
                          color: Color(0xFFEF4444),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Recusar Agendamento',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'O cliente será notificado sobre a recusa',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: secondaryTextColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Card informativo
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFEF4444).withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ao recusar, o agendamento será cancelado e o cliente receberá uma notificação.',
                            style: TextStyle(
                              fontSize: 13,
                              color: textColor,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Campo de motivo
                  Text(
                    'Motivo da Recusa',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: reasonController,
                    maxLines: 4,
                    style: FormStyles.inputTextStyle(context),
                    cursorColor: AppColors.primaryColor,
                    decoration: FormStyles.decorate(
                      context,
                      const InputDecoration(
                        hintText: 'Ex: Horário não disponível, falta de peças, agenda lotada...',
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            side: BorderSide(color: borderColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            'Cancelar',
                            style: TextStyle(
                              color: textColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context, reasonController.text.trim().isEmpty ? 'Sem motivo informado' : reasonController.text.trim());
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF4444),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text(
                            'Confirmar Recusa',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (result != null) {
      try {
        final apiResult = await _apiService.rejectBooking(booking['id'], result);
        if (apiResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento recusado com sucesso! O cliente foi notificado.'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          await _loadBookings(forceRefresh: true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${apiResult['error']}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  Future<void> _confirmPreCompra(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    try {
      final result = await _apiService.put('/pre-compra/$id/confirm', {});
      if (result['success'] == true) {
        _safeSetState(() {
          _pendingBookings.removeWhere((b) => b['id']?.toString() == id);
          final updated = Map<String, dynamic>.from(item);
          updated['status'] = 'confirmado';
          _confirmedBookings.insert(0, updated);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pré-Compra aprovada!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${result['error'] ?? 'Falha ao aprovar'}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _cancelPreCompra(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recusar Pré-Compra'),
        content: const Text('Confirma o cancelamento desta pré-compra?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Recusar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      final result = await _apiService.put('/pre-compra/$id/cancel', {});
      if (result['success'] == true) {
        _safeSetState(() {
          _pendingBookings.removeWhere((b) => b['id']?.toString() == id);
          final updated = Map<String, dynamic>.from(item);
          updated['status'] = 'cancelado';
          _completedBookings.insert(0, updated);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Pré-Compra recusada.'),
              backgroundColor: Color(0xFF6B7280),
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${result['error'] ?? 'Falha ao recusar'}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<void> _suggestNewTimePreCompra(Map<String, dynamic> item) async {
    final id = item['id']?.toString() ?? '';
    if (id.isEmpty) return;
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: Color(0xFF00C977)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null || !mounted) return;
    final pickedTime = await _showWheelTimePicker(context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (pickedTime == null || !mounted) return;
    final newDateTime = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
    );
    try {
      final result = await _apiService.put('/pre-compra/$id', {
        'appointment_date': newDateTime.toIso8601String(),
      });
      if (result['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Novo horário sugerido com sucesso!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
          _loadBookings(forceRefresh: true);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${result['error'] ?? 'Falha ao sugerir horário'}'),
              backgroundColor: const Color(0xFFEF4444),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erro: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    }
  }

  Future<TimeOfDay?> _showWheelTimePicker(BuildContext context, {TimeOfDay? initialTime}) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final initial = initialTime ?? TimeOfDay.now();
    int selectedHour = initial.hour;
    int selectedMinute = (initial.minute / 5).round() * 5;
    if (selectedMinute >= 60) selectedMinute = 55;

    final result = await showModalBottomSheet<TimeOfDay>(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              child: SizedBox(
                height: 320,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Selecione o horário',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(ctx),
                            icon: Icon(Icons.close, color: isDarkMode ? Colors.grey : Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: [
                          const SizedBox(width: 40),
                          Expanded(
                            child: Column(
                              children: [
                                Text('Hora', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: FixedExtentScrollController(initialItem: selectedHour),
                                    itemExtent: 40,
                                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                                      background: const Color(0xFF00C977).withOpacity(0.12),
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setSheetState(() => selectedHour = index);
                                    },
                                    children: List.generate(24, (i) => Center(
                                      child: Text(
                                        i.toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(':', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black87)),
                          Expanded(
                            child: Column(
                              children: [
                                Text('Minuto', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
                                const SizedBox(height: 4),
                                Expanded(
                                  child: CupertinoPicker(
                                    scrollController: FixedExtentScrollController(initialItem: selectedMinute ~/ 5),
                                    itemExtent: 40,
                                    selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                                      background: const Color(0xFF00C977).withOpacity(0.12),
                                    ),
                                    onSelectedItemChanged: (index) {
                                      setSheetState(() => selectedMinute = index * 5);
                                    },
                                    children: List.generate(12, (i) => Center(
                                      child: Text(
                                        (i * 5).toString().padLeft(2, '0'),
                                        style: TextStyle(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w600,
                                          color: isDarkMode ? Colors.white : Colors.black87,
                                        ),
                                      ),
                                    )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, TimeOfDay(hour: selectedHour, minute: selectedMinute)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C977),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0,
                          ),
                          child: const Text('Confirmar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    return result;
  }

  Future<void> _suggestNewTime(Map<String, dynamic> booking) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    final cardColor = ThemeService.getCardColor(isDark);
    final borderColor = ThemeService.getBorderColor(isDark);
    final textColor = ThemeService.getTextColor(isDark);
    final secondaryTextColor = ThemeService.getSecondaryTextColor(isDark);

    // Obter data e hora do agendamento original do cliente
    DateTime? originalDate;
    try {
      final appointmentDateStr = booking['appointment_date']?.toString() ?? 
                                  booking['scheduled_date']?.toString() ?? 
                                  booking['date']?.toString();
      if (appointmentDateStr != null && appointmentDateStr.isNotEmpty) {
        originalDate = DateTime.parse(appointmentDateStr);
      }
    } catch (e) {
      // Se não conseguir parsear, usar data atual + 1 dia
      originalDate = DateTime.now().add(const Duration(days: 1));
    }
    
    if (originalDate == null) {
      originalDate = DateTime.now().add(const Duration(days: 1));
    }

    DateTime? selectedDate = originalDate;
    TimeOfDay? selectedTime = TimeOfDay.fromDateTime(originalDate);
    final reasonController = TextEditingController();
    final dateController = TextEditingController(
      text: '${originalDate.day.toString().padLeft(2, '0')}/${originalDate.month.toString().padLeft(2, '0')}/${originalDate.year}',
    );
    final timeController = TextEditingController(
      text: '${originalDate.hour.toString().padLeft(2, '0')}:${originalDate.minute.toString().padLeft(2, '0')}',
    );

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                border: Border.all(color: borderColor.withOpacity(0.3), width: 1),
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header com ícone
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF59E0B).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.schedule,
                              color: Color(0xFFF59E0B),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Sugerir Novo Horário',
                                  style: TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'O cliente receberá uma notificação para analisar sua sugestão',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.close, color: secondaryTextColor),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Card informativo
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: const Color(0xFFF59E0B),
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Os campos abaixo já estão preenchidos com o horário solicitado pelo cliente. Você pode editá-los conforme necessário.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textColor,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Campo de data editável
                      Text(
                        'Data',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dateController,
                        readOnly: false,
                        enabled: true,
                        keyboardType: TextInputType.datetime,
                        style: FormStyles.inputTextStyle(context),
                        cursorColor: AppColors.primaryColor,
                        decoration: FormStyles.decorate(
                          context,
                          InputDecoration(
                            labelText: 'Data (DD/MM/AAAA)',
                            hintText: 'Ex: 25/12/2024',
                            prefixIcon: const Icon(Icons.calendar_today, color: AppColors.primaryColor),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month, color: AppColors.primaryColor),
                              onPressed: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                                  firstDate: DateTime.now(),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                  builder: (context, child) {
                                    return Theme(
                                      data: Theme.of(context).copyWith(
                                        colorScheme: ColorScheme.dark(
                                          primary: const Color(0xFF00C977),
                                          onPrimary: Colors.white,
                                          surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                          onSurface: isDark ? Colors.white : Colors.black,
                                        ),
                                      ),
                                      child: child!,
                                    );
                                  },
                                );
                                if (picked != null) {
                                  setState(() {
                                    selectedDate = picked;
                                    dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                                  });
                                }
                              },
                            ),
                          ),
                        ),
                        onChanged: (value) {
                          // Tentar parsear a data digitada manualmente
                          final parts = value.split('/');
                          if (parts.length == 3) {
                            try {
                              final day = int.parse(parts[0]);
                              final month = int.parse(parts[1]);
                              final year = int.parse(parts[2]);
                              final parsedDate = DateTime(year, month, day);
                              if (parsedDate.isAfter(DateTime.now().subtract(const Duration(days: 1)))) {
                                setState(() => selectedDate = parsedDate);
                              }
                            } catch (e) {
                              // Ignorar erros de parsing
                            }
                          }
                        },
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 1)),
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.dark(
                                    primary: const Color(0xFF00C977),
                                    onPrimary: Colors.white,
                                    surface: isDark ? const Color(0xFF1A1A1A) : Colors.white,
                                    onSurface: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setState(() {
                              selectedDate = picked;
                              dateController.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 20),
                      
                      Text(
                        'Horário',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await _showWheelTimePicker(context, initialTime: selectedTime);
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF252525) : const Color(0xFFF7F7F7),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: selectedTime != null
                                  ? AppColors.primaryColor
                                  : (isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
                              width: selectedTime != null ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryColor.withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.access_time_rounded, color: AppColors.primaryColor, size: 18),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                timeController.text.isNotEmpty ? timeController.text : 'Selecionar horário',
                                style: TextStyle(
                                  color: timeController.text.isNotEmpty ? textColor : secondaryTextColor,
                                  fontSize: 15,
                                  fontWeight: timeController.text.isNotEmpty ? FontWeight.w600 : FontWeight.w400,
                                ),
                              ),
                              const Spacer(),
                              Icon(Icons.keyboard_arrow_down_rounded, color: secondaryTextColor, size: 22),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Campo de motivo
                      Text(
                        'Motivo (opcional)',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: reasonController,
                        maxLines: 3,
                        style: FormStyles.inputTextStyle(context),
                        cursorColor: AppColors.primaryColor,
                        decoration: FormStyles.decorate(
                          context,
                          const InputDecoration(
                            hintText: 'Ex: Horário não disponível, melhor opção...',
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Botões
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: borderColor),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Cancelar',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: (selectedDate != null && selectedTime != null)
                                  ? () {
                                      final combined = DateTime(
                                        selectedDate!.year,
                                        selectedDate!.month,
                                        selectedDate!.day,
                                        selectedTime!.hour,
                                        selectedTime!.minute,
                                      ).toIso8601String();
                                      Navigator.pop(context, {
                                        'date': combined,
                                        'reason': reasonController.text.trim(),
                                      });
                                    }
                                  : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFF59E0B),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Enviar Sugestão',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && result['date'] != null) {
      try {
        final apiResult = await _apiService.suggestNewTime(
          booking['id'].toString(),
          result['date'] as String,
          (result['reason'] as String?) ?? '',
        );

        if (!mounted) return;

        if (apiResult['success']) {
          await showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.check_circle,
                        color: Color(0xFFF59E0B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Sugestão Enviada!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Builder(
                  builder: (context) {
                    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sua sugestão de horário foi enviada para o cliente com sucesso.',
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.5,
                            color: isDarkMode ? Colors.white : Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF59E0B).withOpacity(0.4),
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: const Color(0xFFF59E0B),
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'O cliente recebeu uma notificação e vai analisar sua sugestão. Você será avisado quando ele autorizar ou negar.',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    height: 1.5,
                                    color: isDarkMode ? Colors.white : const Color(0xFF1F2937),
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadBookings(forceRefresh: true);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Entendi',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Erro: ${apiResult['error']}'),
                backgroundColor: const Color(0xFFEF4444),
              ),
            );
          }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }
}
