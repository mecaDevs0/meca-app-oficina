import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../services/theme_service.dart';
import '../../widgets/theme_switch_widget.dart';

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
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final token = await StorageService.getToken();
      if (token == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      await _apiService.loadToken();
      
      // Carregar agendamentos pendentes
      final pendingResponse = await _apiService.getMyBookings(status: 'pendente_oficina');
      if (pendingResponse['success']) {
        setState(() {
          _pendingBookings = List<Map<String, dynamic>>.from(pendingResponse['data']['bookings'] ?? []);
        });
      }

      // Carregar agendamentos confirmados
      final confirmedResponse = await _apiService.getMyBookings(status: 'confirmado');
      if (confirmedResponse['success']) {
        setState(() {
          _confirmedBookings = List<Map<String, dynamic>>.from(confirmedResponse['data']['bookings'] ?? []);
        });
      }

      // Carregar agendamentos concluídos
      final completedResponse = await _apiService.getMyBookings(status: 'concluido');
      if (completedResponse['success']) {
        setState(() {
          _completedBookings = List<Map<String, dynamic>>.from(completedResponse['data']['bookings'] ?? []);
        });
      }
      
    } catch (e) {
      print('Erro ao carregar agendamentos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final bgColor = themeService.isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA);
    final textColor = themeService.isDarkMode ? Colors.white : const Color(0xFF111827);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Agenda'),
        backgroundColor: bgColor,
        elevation: 0,
        foregroundColor: textColor,
        actions: [
          const ThemeSwitchButton(),
        ],
      ),
      body: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Agenda',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gerencie seus agendamentos',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: ThemeService.getSecondaryTextColor(themeService.isDarkMode),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: ThemeService.getCardColor(themeService.isDarkMode),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: ThemeService.getBorderColor(themeService.isDarkMode),
                      width: 1,
                    ),
                  ),
                  child: TabBar(
                    isScrollable: true,
                    controller: _tabController,
                    indicator: BoxDecoration(
                      color: const Color(0xFF00C977),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: ThemeService.getSecondaryTextColor(themeService.isDarkMode),
                    labelStyle: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontWeight: FontWeight.w400,
                      fontSize: 12,
                    ),
                    labelPadding: const EdgeInsets.symmetric(horizontal: 12),
                    tabs: [
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _pendingBookings.isEmpty ? Colors.grey.withOpacity(0.3) : const Color(0xFFF59E0B).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.pending, 
                                  size: 14,
                                  color: _pendingBookings.isEmpty ? Colors.grey : const Color(0xFFF59E0B),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pendentes (${_pendingBookings.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _pendingBookings.isEmpty ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _confirmedBookings.isEmpty ? Colors.grey.withOpacity(0.3) : const Color(0xFF10B981).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.check_circle, 
                                  size: 14,
                                  color: _confirmedBookings.isEmpty ? Colors.grey : const Color(0xFF10B981),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Confirmados (${_confirmedBookings.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _confirmedBookings.isEmpty ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Tab(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: _completedBookings.isEmpty ? Colors.grey.withOpacity(0.3) : const Color(0xFF6B7280).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Icon(
                                  Icons.done_all, 
                                  size: 14,
                                  color: _completedBookings.isEmpty ? Colors.grey : const Color(0xFF6B7280),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Concluídos (${_completedBookings.length})',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: _completedBookings.isEmpty ? Colors.grey : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildBookingsList(_pendingBookings, 'pending'),
                      _buildBookingsList(_confirmedBookings, 'confirmed'),
                      _buildBookingsList(_completedBookings, 'completed'),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingsList(List<Map<String, dynamic>> bookings, String type) {
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
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                      color: ThemeService.getTextColor(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptySubtitle(type),
              style: const TextStyle(
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
    
    return Container(
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
                  const Icon(
                    Icons.directions_car,
                    size: 16,
                    color: ThemeService.getSecondaryTextColor(isDark),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${booking['vehicle_snapshot']['marca']} ${booking['vehicle_snapshot']['modelo']} - ${booking['vehicle_snapshot']['placa']}',
                    style: const TextStyle(
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
                color: ThemeService.getSecondaryTextColor(isDark),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(booking['appointment_date']),
                style: const TextStyle(
                  fontSize: 14,
                  color: ThemeService.getSecondaryTextColor(isDark),
                ),
              ),
              const Spacer(),
              if (booking['estimated_price'] != null)
                Text(
                  'R\$ ${(booking['estimated_price'] / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
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
                  const Icon(
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
                    label: const Text('Aprovar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981)),
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
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Recusar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444)),
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
                    icon: const Icon(Icons.schedule, size: 16),
                    label: const Text('Sugerir'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFF59E0B),
                      side: const BorderSide(color: Color(0xFFF59E0B)),
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
              decoration: const InputDecoration(
                hintText: 'Motivo da recusa...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
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
    // TODO: Implementar seleção de novo horário
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Funcionalidade de sugerir novo horário em desenvolvimento!'),
        backgroundColor: Color(0xFFF59E0B),
      ),
    );
  }
}
