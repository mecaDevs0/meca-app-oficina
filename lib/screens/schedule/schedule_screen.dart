import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/animation_widgets.dart';
import '../../utils/form_styles.dart';
import '../../core/app_colors.dart';
import '../bookings/booking_detail_screen.dart';

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
                style: TextStyle(
                  fontSize: 13,
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

  Future<void> _loadBookings() async {
    _safeSetState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar agendamentos pendentes
      final pendingResponse = await _apiService.getMyBookings(status: 'pendente_oficina');
      if (pendingResponse['success']) {
        _safeSetState(() {
          _pendingBookings = List<Map<String, dynamic>>.from(pendingResponse['data']['bookings'] ?? []);
        });
      }

      // Carregar agendamentos confirmados
      final confirmedResponse = await _apiService.getMyBookings(status: 'confirmado');
      if (confirmedResponse['success']) {
        _safeSetState(() {
          _confirmedBookings = List<Map<String, dynamic>>.from(confirmedResponse['data']['bookings'] ?? []);
        });
      }

      // Carregar agendamentos concluídos
      final completedResponse = await _apiService.getMyBookings(status: 'concluido');
      if (completedResponse['success']) {
        _safeSetState(() {
          _completedBookings = List<Map<String, dynamic>>.from(completedResponse['data']['bookings'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
    } finally {
      _safeSetState(() => _isLoading = false);
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
                        _buildBookingsList(_confirmedBookings, 'confirmed'),
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
      onRefresh: _loadBookings,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: bookings.length,
        itemBuilder: (context, index) {
          final booking = bookings[index];
          return _buildBookingCard(booking, type);
        },
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

  Widget _buildBookingCard(Map<String, dynamic> booking, String type) {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;
    
    return InkWell(
      onTap: () async {
        final result = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => BookingDetailScreen(booking: booking),
          ),
        );
        if (result == true) {
          _loadBookings();
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
              Container(
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
              Icon(
                Icons.access_time,
                size: 16,
                color: ThemeService.getSecondaryTextColor(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(booking['appointment_date']),
                style: TextStyle(
                  fontSize: 14,
                  color: ThemeService.getSecondaryTextColor(isDark),
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
                    icon: Icon(Icons.check, size: 16),
                    label: const Text('Aprovar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _rejectBooking(booking),
                    icon: Icon(Icons.close, size: 16),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _suggestNewTime(booking),
                    icon: Icon(Icons.schedule, size: 16),
                    label: const Text('Sugerir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
                      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    switch (status) {
      case 'pendente_oficina':
        return 'Pendente';
      case 'confirmado':
        return 'Confirmado';
      case 'concluido':
        return 'Concluído';
      case 'cancelado':
        return 'Cancelado';
      case 'recusado':
        return 'Recusado';
      default:
        return 'Desconhecido';
    }
  }

  String _formatDateTime(String? dateTime) {
    if (dateTime == null) return 'Data não informada';
    
    try {
      final date = DateTime.parse(dateTime);
      return '${date.day}/${date.month}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateTime;
    }
  }

  Future<void> _confirmBooking(Map<String, dynamic> booking) async {
    try {
      final result = await _apiService.confirmBooking(booking['id']);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Agendamento aprovado com sucesso!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        _loadBookings();
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
    final reasonController = TextEditingController();
    
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Recusar Agendamento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Informe o motivo da recusa:'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              maxLines: 3,
              style: FormStyles.inputTextStyle(context),
              cursorColor: AppColors.primaryColor,
              decoration: FormStyles.decorate(
                context,
                const InputDecoration(
                  hintText: 'Motivo da recusa...',
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            child: const Text('Recusar'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      try {
        final apiResult = await _apiService.rejectBooking(booking['id'], result);
        if (apiResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Agendamento recusado!'),
              backgroundColor: Color(0xFFEF4444),
            ),
          );
          _loadBookings();
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

  Future<void> _suggestNewTime(Map<String, dynamic> booking) async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final isDark = themeService.isDarkMode;

    DateTime? selectedDate;
    TimeOfDay? selectedTime;
    final reasonController = TextEditingController();

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
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
                    Text(
                      'Sugerir Novo Horário',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.calendar_today, color: Color(0xFF00C977)),
                      title: Text(
                        selectedDate == null
                            ? 'Selecionar data'
                            : '${selectedDate!.day.toString().padLeft(2, '0')}/${selectedDate!.month.toString().padLeft(2, '0')}/${selectedDate!.year}',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
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
                          setState(() => selectedDate = picked);
                        }
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                      title: Text(
                        selectedTime == null
                            ? 'Selecionar horário'
                            : '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(color: isDark ? Colors.white : Colors.black),
                      ),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: selectedTime ?? TimeOfDay.now(),
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
                          setState(() => selectedTime = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: reasonController,
                      maxLines: 3,
                      style: FormStyles.inputTextStyle(context),
                      cursorColor: AppColors.primaryColor,
                      decoration: FormStyles.decorate(
                        context,
                        const InputDecoration(
                          labelText: 'Motivo (opcional)',
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancelar'),
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
                              backgroundColor: const Color(0xFF00C977),
                            ),
                            child: const Text('Sugerir'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    reasonController.dispose();

    if (result != null && result['date'] != null) {
      try {
        final apiResult = await _apiService.suggestNewTime(
          booking['id'].toString(),
          result['date'] as String,
          (result['reason'] as String?) ?? '',
        );

        if (!mounted) return;

        if (apiResult['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Novo horário sugerido com sucesso!'),
              backgroundColor: Color(0xFF00C977),
            ),
          );
          _loadBookings();
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
