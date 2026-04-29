import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
import '../../widgets/beautiful_error_snackbar.dart';
import '../bookings/build_quote_screen.dart';
import '../bookings/evidence_upload_screen.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic> booking;

  const BookingDetailScreen({Key? key, required this.booking}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> with WidgetsBindingObserver {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _bookingDetails;
  Map<String, dynamic>? _paymentData; // PASSO 15: Dados do pagamento
  bool _loading = true;

  void _showToast(String message, {String? title, bool isError = false, bool isWarning = false}) {
    if (!mounted) return;
    if (isError) {
      BeautifulErrorSnackbar.show(context, message, title: title);
    } else if (isWarning) {
      BeautifulErrorSnackbar.showWarning(context, message, title: title);
    } else {
      BeautifulErrorSnackbar.showSuccess(context, message, title: title);
    }
  }

  bool _hasCheckIn(Map<String, dynamic> booking) {
    final v = booking['check_in_at'] ?? booking['checkInAt'] ?? booking['check_in'];
    return v != null && v.toString().trim().isNotEmpty;
  }

  String? _formatCheckInAt(Map<String, dynamic> booking) {
    final raw = booking['check_in_at'] ?? booking['checkInAt'] ?? booking['check_in'];
    if (raw == null) return null;
    try {
      final dt = DateTime.parse(raw.toString());
      return DateFormat('dd/MM/yyyy HH:mm').format(dt.toLocal());
    } catch (_) {
      return raw.toString();
    }
  }

  Future<void> _promptCheckInAndDo(String bookingId) async {
    if (bookingId.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check-in obrigatório'),
        content: const Text(
          'Para iniciar o serviço (Opção 2), registre a chegada do veículo (check-in) primeiro.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Agora não'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Fazer check-in'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _apiService.checkInVehicle(bookingId);
    if (!mounted) return;
    if (result['success'] == true) {
      await _loadBookingDetails(forceRefresh: true);
      _showToast('Check-in realizado! Agora você já pode iniciar o serviço.');
    } else {
      _showToast(result['error']?.toString() ?? 'Não foi possível fazer o check-in.', isError: true);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBookingDetails();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _loadBookingDetails();
    }
  }

  Future<void> _loadBookingDetails({bool forceRefresh = false}) async {
    setState(() => _loading = true);
    
    try {
      final bookingId = widget.booking['id']?.toString() ?? '';
      
      if (bookingId.isNotEmpty) {
        // IMPORTANTE: Se forceRefresh, adicionar timestamp para forçar nova requisição
        final result = await _apiService.getBookingDetails(
          bookingId,
          forceRefresh: forceRefresh,
        );
        
        if (result['success'] == true && result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);
          setState(() {
            _bookingDetails = data;
          });
        } else {
          setState(() {
            _bookingDetails = widget.booking;
          });
        }
      } else {
        setState(() {
          _bookingDetails = widget.booking;
        });
      }
    } catch (e) {
      setState(() {
        _bookingDetails = widget.booking;
      });
    } finally {
      setState(() => _loading = false);
    }
  }

  /// Verifica se é o dia do agendamento (considera apenas a data, não a hora)
  bool _isAppointmentDay(Map<String, dynamic> booking) {
    try {
      final appointmentDateStr = booking['appointment_date']?.toString() ?? 
                                  booking['scheduled_date']?.toString() ?? 
                                  booking['date']?.toString();
      
      if (appointmentDateStr == null || appointmentDateStr.isEmpty) {
        return false;
      }

      // Parse da data do agendamento
      final appointmentDate = DateTime.parse(appointmentDateStr);
      final now = DateTime.now();
      
      // Converter para UTC para evitar problemas de timezone (igual à API)
      final appointmentUTC = DateTime.utc(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
      final todayUTC = DateTime.utc(
        now.year,
        now.month,
        now.day,
      );
      
      // Comparar diretamente ano, mês e dia
      return appointmentUTC.year == todayUTC.year &&
             appointmentUTC.month == todayUTC.month &&
             appointmentUTC.day == todayUTC.day;
    } catch (e) {
      print('❌ [_isAppointmentDay] Erro ao verificar data: $e');
      print('   - appointment_date: ${booking['appointment_date']}');
      return false;
    }
  }
  
  /// Retorna informações sobre o dia do agendamento para mensagens
  String _getAppointmentDayInfo(Map<String, dynamic> booking) {
    try {
      final appointmentDateStr = booking['appointment_date']?.toString() ?? 
                                  booking['scheduled_date']?.toString() ?? 
                                  booking['date']?.toString();
      
      if (appointmentDateStr == null || appointmentDateStr.isEmpty) {
        return 'Data não informada';
      }

      final appointmentDate = DateTime.parse(appointmentDateStr);
      final now = DateTime.now();
      
      // Converter para UTC para evitar problemas de timezone (igual à API)
      final appointmentUTC = DateTime.utc(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
      );
      final todayUTC = DateTime.utc(
        now.year,
        now.month,
        now.day,
      );
      
      // Comparar diretamente ano, mês e dia
      final isToday = appointmentUTC.year == todayUTC.year &&
                      appointmentUTC.month == todayUTC.month &&
                      appointmentUTC.day == todayUTC.day;
      
      if (isToday) {
        return 'Hoje';
      } else if (appointmentUTC.isBefore(todayUTC)) {
        return 'Passado';
      } else {
        final difference = appointmentUTC.difference(todayUTC).inDays;
        if (difference == 1) {
          return 'Amanhã';
        } else {
          return 'Em $difference dias';
        }
      }
    } catch (e) {
      return 'Data não informada';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    final statusFromDetails = (_bookingDetails?['status'] ?? '').toString().toLowerCase().trim();
    final statusFromWidget = (widget.booking['status'] ?? '').toString().toLowerCase().trim();
    final statusFinal = statusFromDetails.isNotEmpty ? statusFromDetails : statusFromWidget;
    
    final normalizedStatus = statusFinal == 'confirmed' ? 'confirmado' : 
                            statusFinal == 'confirmado' ? 'confirmado' :
                            statusFinal;
    
    final booking = Map<String, dynamic>.from(_bookingDetails ?? widget.booking);
    booking['status'] = normalizedStatus;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey[50],
      bottomNavigationBar: _buildBottomActionBar(booking, isDarkMode, statusFinal, normalizedStatus),
      appBar: AppBar(
        title: const Text(
          'Detalhes do Agendamento',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF00C977),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadBookingDetails();
        },
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF00C977)))
            : SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  children: [
                    // Status do agendamento
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: _getStatusColor(statusFinal).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _getStatusText(statusFinal),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _getStatusColor(statusFinal),
                              ),
                            ),
                          ),
                          if (statusFinal == 'pendente_cliente') ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.amber.shade200),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 20, color: Colors.amber.shade800),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Aguardando aprovação do cliente. O cliente precisa aprovar o orçamento de R\$ ${((booking['final_price'] ?? 0) / 100).toStringAsFixed(2)} antes de prosseguir com o pagamento.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade900,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            booking['service_name'] ?? 'Serviço',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Card informativo sobre situação atual (TOPO)
                    _buildStatusInfoCard(booking, isDarkMode, normalizedStatus),

                    // Informações do cliente
                    Builder(builder: (_) {
                      final customerFullName = [booking['customer_name'], booking['customer_last_name']]
                          .where((s) => s != null && s.toString().isNotEmpty)
                          .join(' ')
                          .trim();
                      return _buildInfoCard(
                      'Informações do Cliente',
                      [
                        _buildInfoRow('Nome', customerFullName.isEmpty ? 'Não informado' : customerFullName, Icons.person),
                        _buildInfoRow('Telefone', booking['customer_phone'] ?? 'Não informado', Icons.phone),
                        _buildInfoRow('Email', booking['customer_email'] ?? 'Não informado', Icons.email),
                      ],
                      isDarkMode,
                    );
                    }),

                    // Informações do veículo (marca/modelo vindos da API: vehicle_brand, vehicle_model)
                    _buildInfoCard(
                      'Informações do Veículo',
                      [
                        _buildInfoRow('Marca', _vehicleDisplayValue(booking['vehicle_brand']), Icons.directions_car),
                        _buildInfoRow('Modelo', _vehicleDisplayValue(booking['vehicle_model']), Icons.directions_car),
                        _buildInfoRow('Placa', _vehicleDisplayValue(booking['vehicle_plate']), Icons.confirmation_number),
                      ],
                      isDarkMode,
                    ),
                    
                    // Informações do agendamento
                    _buildInfoCard(
                      'Informações do Agendamento',
                      [
                        _buildInfoRow('Data', _formatDate(booking['appointment_date']), Icons.calendar_today),
                        // Exibir horário fixo ou janela de horário
                        if (booking['schedule_type'] == 'time_window' && 
                            booking['time_window_start'] != null && 
                            booking['time_window_end'] != null) ...[
                          _buildInfoRow(
                            'Janela de Horário', 
                            '${_formatTime(booking['time_window_start'])} até ${_formatTime(booking['time_window_end'])}', 
                            Icons.schedule
                          ),
                        ] else ...[
                          _buildInfoRow('Hora', _formatTime(booking['appointment_date']), Icons.access_time),
                        ],
                        if (booking['estimated_price'] != null)
                          _buildInfoRow('Valor Estimado', 'R\$ ${(booking['estimated_price'] / 100).toStringAsFixed(2)}', Icons.attach_money),
                      ],
                      isDarkMode,
                    ),
                    
                    // Observações
                    if (booking['customer_notes'] != null && booking['customer_notes'].toString().isNotEmpty)
                      _buildInfoCard(
                        'Observações do Cliente',
                        [
                          _buildInfoRow('', booking['customer_notes'].toString(), Icons.note),
                        ],
                        isDarkMode,
                      ),
                    
                    // Imagens enviadas pelo cliente
                    Builder(
                      builder: (context) {
                        final hasUploads = _hasCustomerUploads(booking);
                        if (hasUploads) {
                          return _buildCustomerUploadsCard(booking, isDarkMode);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                    
                    // PASSO 15: Card de informações de pagamento (se pago)
                    if ((statusFinal == 'pago' || statusFinal == 'paid' || statusFinal == 'completed') && _paymentData != null)
                      _buildPaymentInfoCard(booking, isDarkMode),
                    
                    const SizedBox(height: 20),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children, bool isDarkMode) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  String _vehicleDisplayValue(dynamic value) {
    if (value == null) return 'Não informado';
    final s = value.toString().trim();
    return s.isEmpty ? 'Não informado' : s;
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (label.isNotEmpty)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode ? Colors.white : Colors.black87,
                    fontWeight: label.isEmpty ? FontWeight.normal : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text, IconData icon, bool isDarkMode) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 18,
          color: const Color(0xFF00B4D8),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.black87,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showFinishServiceDialog(Map<String, dynamic> booking) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final quoteItems = booking['quote_items'] as List<dynamic>? ?? [];
    final diagnosticCents = num.tryParse(booking['diagnostic_value']?.toString() ?? '') ?? 0;
    final finalPriceCents = num.tryParse(booking['final_price']?.toString() ?? '') ?? 0;
    final diagnosticReais = diagnosticCents / 100.0;
    final finalPriceReais = finalPriceCents / 100.0;
    final quoteReason = booking['quote_reason']?.toString();

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final cardColor = isDarkMode ? const Color(0xFF1A1A1A) : Colors.white;
        final textColor = isDarkMode ? Colors.white : Colors.black87;
        final subtextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

        return Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF00C977).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF00C977), size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Finalizar Serviço', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: textColor)),
                            const SizedBox(height: 2),
                            Text('Confira o orçamento aprovado', style: TextStyle(fontSize: 13, color: subtextColor)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF222222) : const Color(0xFFF8F8F8),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDarkMode ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Itens do Orçamento', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: subtextColor)),
                        const SizedBox(height: 10),
                        ...quoteItems.map((item) {
                          final desc = item['description']?.toString() ?? 'Item';
                          final qty = int.tryParse(item['quantity']?.toString() ?? '') ?? 1;
                          final unitCents = num.tryParse(item['unit_price']?.toString() ?? '') ?? 0;
                          final totalReais = (unitCents * qty) / 100.0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24, height: 24,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C977).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Center(child: Text('$qty', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: const Color(0xFF00C977)))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Text(desc, style: TextStyle(fontSize: 14, color: textColor))),
                                Text('R\$ ${totalReais.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                              ],
                            ),
                          );
                        }),
                        if (diagnosticReais > 0) ...[
                          const Divider(height: 16),
                          Row(
                            children: [
                              Icon(Icons.search_rounded, size: 16, color: subtextColor),
                              const SizedBox(width: 8),
                              Expanded(child: Text('Diagnóstico', style: TextStyle(fontSize: 14, color: textColor))),
                              Text('R\$ ${diagnosticReais.toStringAsFixed(2).replaceAll('.', ',')}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor)),
                            ],
                          ),
                        ],
                        if (quoteReason != null && quoteReason.trim().isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.message_rounded, size: 14, color: subtextColor),
                              const SizedBox(width: 6),
                              Expanded(child: Text(quoteReason.trim(), style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: subtextColor))),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF00C977), Color(0xFF00B369)]),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Valor Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text('R\$ ${finalPriceReais.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_rounded, size: 18, color: Colors.orange),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Após finalizar, o valor não poderá ser alterado. Se precisar mudar, use "Editar Orçamento" antes.',
                            style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.orange[200] : Colors.orange[800], height: 1.3),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, false),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: subtextColor.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text('Cancelar', style: TextStyle(color: subtextColor, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, true),
                            icon: const Icon(Icons.check_circle_rounded, size: 20),
                            label: const Text('Finalizar Serviço', style: TextStyle(fontWeight: FontWeight.w700)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00C977),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
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

    if (confirmed != true) return;

    final bookingId = booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    final items = quoteItems.map((item) => {
      'description': item['description']?.toString() ?? 'Item',
      'quantity': int.tryParse(item['quantity']?.toString() ?? '') ?? 1,
      'unitPrice': int.tryParse(item['unit_price']?.toString() ?? '') ?? 0,
    }).toList();

    final result = await _apiService.finishService(
      bookingId,
      items: items,
      diagnosticValueCents: diagnosticCents.toInt(),
      quoteReason: quoteReason,
    );

    if (!mounted) return;
    if (result['success'] == true) {
      _showToast('Serviço finalizado! O cliente foi notificado para pagamento.');
      await _loadBookingDetails(forceRefresh: true);
    } else {
      _showToast(result['error']?.toString() ?? 'Erro ao finalizar serviço.', isError: true);
    }
  }

  Future<void> _showRejectDialog(Map<String, dynamic> booking) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;
    
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
                    style: TextStyle(color: textColor),
                    cursorColor: const Color(0xFF00C977),
                    decoration: InputDecoration(
                      hintText: 'Ex: Horário não disponível, falta de peças, agenda lotada...',
                      hintStyle: TextStyle(color: secondaryTextColor),
                      filled: true,
                      fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: borderColor),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
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
      final bookingId = booking['id']?.toString() ?? '';
      if (bookingId.isEmpty) {
        _showToast('ID do agendamento não encontrado.', isError: true);
        return;
      }

        final apiResult = await _apiService.rejectBooking(
        bookingId,
          result,
      );

      if (!mounted) return;

        if (apiResult['success'] == true) {
        _showToast('Agendamento recusado. O cliente foi notificado.');
        Navigator.of(context).pop(true);
      } else {
        _showToast(apiResult['error']?.toString() ?? 'Erro ao recusar agendamento.', isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showToast('Erro: ${e.toString()}', isError: true);
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

  Future<void> _showSuggestTimeDialog(Map<String, dynamic> booking) async {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDarkMode ? const Color(0xFF2A2A2A) : Colors.white;
    final borderColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final secondaryTextColor = isDarkMode ? Colors.grey[400]! : Colors.grey[600]!;

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
                        style: TextStyle(color: textColor),
                        cursorColor: const Color(0xFF00C977),
                        decoration: InputDecoration(
                          labelText: 'Data (DD/MM/AAAA)',
                          labelStyle: TextStyle(color: secondaryTextColor),
                          hintText: 'Ex: 25/12/2024',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          prefixIcon: const Icon(Icons.calendar_today, color: Color(0xFF00C977)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_month, color: Color(0xFF00C977)),
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
                                        surface: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                                        onSurface: isDarkMode ? Colors.white : Colors.black,
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
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
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
                                    surface: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                                    onSurface: isDarkMode ? Colors.white : Colors.black,
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
                      
                      // Campo de horário editável
                      Text(
                        'Horário',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: timeController,
                        readOnly: false,
                        enabled: true,
                        keyboardType: TextInputType.datetime,
                        style: TextStyle(color: textColor),
                        cursorColor: const Color(0xFF00C977),
                        decoration: InputDecoration(
                          labelText: 'Horário (HH:MM)',
                          labelStyle: TextStyle(color: secondaryTextColor),
                          hintText: 'Ex: 14:30',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          prefixIcon: const Icon(Icons.access_time, color: Color(0xFF00C977)),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.schedule, color: Color(0xFF00C977)),
                            onPressed: () async {
                              final picked = await _showWheelTimePicker(context, initialTime: selectedTime);
                              if (picked != null) {
                                setState(() {
                                  selectedTime = picked;
                                  timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                                });
                              }
                            },
                          ),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                          ),
                        ),
                        onChanged: (value) {
                          // Tentar parsear o horário digitado manualmente
                          final parts = value.split(':');
                          if (parts.length == 2) {
                            try {
                              final hour = int.parse(parts[0]);
                              final minute = int.parse(parts[1]);
                              if (hour >= 0 && hour < 24 && minute >= 0 && minute < 60) {
                                setState(() => selectedTime = TimeOfDay(hour: hour, minute: minute));
                              }
                            } catch (e) {
                              // Ignorar erros de parsing
                            }
                          }
                        },
                        onTap: () async {
                          final picked = await _showWheelTimePicker(context, initialTime: selectedTime);
                          if (picked != null) {
                            setState(() {
                              selectedTime = picked;
                              timeController.text = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                            });
                          }
                        },
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
                        style: TextStyle(color: textColor),
                        cursorColor: const Color(0xFF00C977),
                        decoration: InputDecoration(
                          hintText: 'Ex: Horário não disponível, melhor opção...',
                          hintStyle: TextStyle(color: secondaryTextColor),
                          filled: true,
                          fillColor: isDarkMode ? Colors.grey[900] : Colors.grey[100],
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: borderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
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

    // Dispose dos controllers apenas após o modal fechar completamente
    try {
      if (result != null && result['date'] != null) {
        try {
          final bookingId = booking['id']?.toString() ?? '';
          if (bookingId.isEmpty) {
            _showToast('ID do agendamento não encontrado.', isError: true);
            return;
          }
          
          final apiResult = await _apiService.suggestNewTime(
            bookingId,
            result['date'] as String,
            (result['reason'] as String?) ?? '',
          );

          if (!mounted) return;

          if (apiResult['success']) {
            // Mostrar modal informativo
            final isDarkMode = Theme.of(context).brightness == Brightness.dark;
            await showDialog(
              context: context,
              barrierDismissible: false,
              builder: (context) => AlertDialog(
                backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
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
                    Expanded(
                      child: Text(
                        'Sugestão Enviada!',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
                content: Column(
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
                ),
                actions: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      _loadBookingDetails();
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
            _showToast(apiResult['error']?.toString() ?? 'Erro ao sugerir novo horário.', isError: true);
          }
        } catch (e) {
          if (!mounted) return;
          _showToast('Erro: ${e.toString()}', isError: true);
        }
      }
    } finally {
      // Dispose dos controllers apenas após processar o resultado
      reasonController.dispose();
      dateController.dispose();
      timeController.dispose();
    }
  }

  /// Card de status: apenas uma frase curta e didática (sem título/subtítulo). Menos texto = app mais simples.
  Widget _buildStatusInfoCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinal) {
    String phrase = '';
    if (statusFinal == 'pending' || statusFinal == 'pendente_oficina' || statusFinal == 'pendente') {
      phrase = 'O cliente solicitou. Aprove, recuse ou sugira outro horário.';
    } else if (statusFinal == 'confirmado' || statusFinal == 'confirmed') {
      phrase = 'Escolha como deseja prosseguir.';
    } else if (statusFinal == 'pendente_cliente') {
      phrase = 'Orçamento enviado. Aguarde a aprovação do cliente.';
    } else if (statusFinal == 'in_progress' || statusFinal == 'started' || statusFinal == 'em_andamento') {
      phrase = 'Serviço em andamento. Use "Editar orçamento" se precisar alterar o valor.';
    } else if (statusFinal == 'finalizado_aguardando_pagamento' || statusFinal == 'finalizado') {
      phrase = 'Serviço finalizado. Aguardando pagamento do cliente.';
    } else if (statusFinal == 'pago' || statusFinal == 'paid' || statusFinal == 'completed') {
      phrase = 'Pagamento confirmado. Serviço concluído.';
    } else if (statusFinal == 'aguardando_aprovacao_finalizacao' || statusFinal == 'awaiting_finalization_approval') {
      phrase = 'Aguarde o cliente aprovar a finalização.';
    }
    if (phrase.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Text(
        phrase,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: isDarkMode ? Colors.grey[300] : Colors.grey[800],
          height: 1.35,
        ),
      ),
    );
  }

  // PASSO 15: Card de informações de pagamento
  Widget _buildPaymentInfoCard(Map<String, dynamic> booking, bool isDarkMode) {
    if (_paymentData == null) return const SizedBox.shrink();

    final payment = _paymentData!;
    final amount = (payment['amount'] ?? 0).toDouble();
    final workshopAmount = (payment['workshop_amount'] ?? 0).toDouble();
    final mecaFee = (payment['meca_fee_amount'] ?? 0).toDouble();
    final paymentMethod = payment['payment_method'] ?? 'N/A';
    
    final NumberFormat currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A3A2A) : Colors.green.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.green.shade300, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
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
                  color: Colors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.payments,
                  color: Colors.green,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Pagamento Confirmado',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.green.shade900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Valor pago pelo cliente
          _buildPaymentRow(
            'Valor Pago pelo Cliente',
            currencyFormat.format(amount),
            Icons.attach_money,
            isDarkMode,
            Colors.blue,
          ),
          const Divider(height: 24),
          // Taxa MECA
          _buildPaymentRow(
            'Taxa MECA (${((payment['meca_fee_percentage'] ?? 0) * 100).toStringAsFixed(0)}%)',
            currencyFormat.format(mecaFee),
            Icons.percent,
            isDarkMode,
            Colors.orange,
          ),
          const Divider(height: 24),
          // Valor que a oficina vai receber
          _buildPaymentRow(
            'Valor que Você Vai Receber',
            currencyFormat.format(workshopAmount),
            Icons.account_balance_wallet,
            isDarkMode,
            Colors.green,
            isHighlight: true,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Método: ${paymentMethod == 'CREDIT_CARD' ? 'Cartão de Crédito' : paymentMethod == 'PIX' ? 'PIX' : paymentMethod}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(String label, String value, IconData icon, bool isDarkMode, Color color, {bool isHighlight = false}) {
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isHighlight ? color : (isDarkMode ? Colors.grey[400] : Colors.grey[600]),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: isHighlight ? 20 : 18,
                  color: isHighlight ? color : (isDarkMode ? Colors.white : Colors.black87),
                  fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Bottom Action Bar (v3.0) ──────────────────────────────────────────

  Widget _actionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16),
            const SizedBox(width: 4),
            Flexible(
              child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12), overflow: TextOverflow.ellipsis, maxLines: 1),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _getActionButtons(Map<String, dynamic> booking, bool isDarkMode, String statusFinal, String normalizedStatus) {
    final isPendingWorkshop = statusFinal == 'pendente_oficina' || statusFinal == 'pending' || normalizedStatus == 'pendente_oficina';
    final isConfirmed = statusFinal == 'confirmado' || normalizedStatus == 'confirmado';
    final isEmAndamento = statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress';
    final isAppointmentDay = _isAppointmentDay(booking);
    final hasCheckIn = _hasCheckIn(booking);
    final quoteStatus = booking['quote_status']?.toString();
    final quoteItems = booking['quote_items'] as List?;
    final hasQuoteItems = quoteItems != null && quoteItems.isNotEmpty;
    final hasFinalPrice = booking['final_price'] != null && booking['final_price'] != 0;
    final hasApprovedQuote = (quoteStatus == 'approved' || quoteStatus == 'final') && (hasQuoteItems || hasFinalPrice);
    final hasSentQuote = (hasQuoteItems || hasFinalPrice) && quoteStatus != null && quoteStatus != 'null';

    if (isPendingWorkshop) {
      return [
        _actionButton('Recusar', Icons.cancel, Colors.red, () => _showRejectDialog(booking)),
        _actionButton('Reagendar', Icons.schedule, Colors.orange, () => _showSuggestTimeDialog(booking)),
        _actionButton('Aprovar', Icons.check_circle, const Color(0xFF00C977), () async {
          final bookingId = booking['id']?.toString() ?? '';
          if (bookingId.isEmpty) return;
          final result = await _apiService.confirmBooking(bookingId);
          if (!mounted) return;
          if (result['success'] == true) {
            await _loadBookingDetails(forceRefresh: true);
            _showToast('Agendamento aprovado!');
          } else {
            _showToast(result['error']?.toString() ?? 'Erro ao aprovar.', isError: true);
          }
        }),
      ];
    }

    if (isConfirmed && isAppointmentDay) {
      if (!hasCheckIn) {
        return [
          _actionButton('Check-in do Veículo', Icons.directions_car, const Color(0xFF3B82F6), () async {
            final bookingId = booking['id']?.toString() ?? '';
            if (bookingId.isEmpty) return;
            final result = await _apiService.checkInVehicle(bookingId);
            if (!mounted) return;
            if (result['success'] == true) {
              await _loadBookingDetails(forceRefresh: true);
              _showToast('Check-in realizado!');
            } else {
              _showToast(result['error']?.toString() ?? 'Erro no check-in.', isError: true);
            }
          }),
        ];
      } else {
        return [
          _actionButton('Evidências', Icons.photo_camera, const Color(0xFF3B82F6), () {
            Navigator.push(context, MaterialPageRoute(
              builder: (context) => EvidenceUploadScreen(bookingId: booking['id'] ?? '', booking: booking),
            ));
          }),
          _actionButton('Iniciar Serviço', Icons.play_arrow, const Color(0xFF00C977), () async {
            final bookingId = booking['id']?.toString() ?? '';
            if (bookingId.isEmpty) return;
            final confirm = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                title: const Text('Iniciar Serviço'),
                content: const Text('O cliente receberá uma notificação de que o serviço começou.'),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00C977)),
                    child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            );
            if (confirm != true) return;
            final result = await _apiService.startService(bookingId);
            if (!mounted) return;
            if (result['success'] == true) {
              await _loadBookingDetails(forceRefresh: true);
              _showToast('Serviço iniciado!');
            } else {
              _showToast(result['error']?.toString() ?? 'Erro ao iniciar.', isError: true);
            }
          }),
        ];
      }
    }

    if (isEmAndamento) {
      final quoteButton = _actionButton(
        hasSentQuote ? 'Editar Orçamento' : 'Enviar Orçamento',
        hasSentQuote ? Icons.edit_note_rounded : Icons.request_quote_rounded,
        Colors.orange,
        () async {
          final existingItems = booking['quote_items'] as List<dynamic>?;
          final existingDiagnostic = int.tryParse(booking['diagnostic_value']?.toString() ?? '');
          final result = await Navigator.push(context, MaterialPageRoute(
            builder: (context) => BuildQuoteScreen(
              bookingId: booking['id'] ?? '',
              existingItems: existingItems?.map((item) => {
                'description': item['description'] ?? '',
                'quantity': item['quantity'] ?? 1,
                'unit_price': item['unit_price'] ?? 0,
              }).toList(),
              existingDiagnosticValue: existingDiagnostic,
              isEditMode: hasSentQuote,
            ),
          ));
          if (result == true) {
            await _loadBookingDetails(forceRefresh: true);
          }
        },
      );

      final evidenceButton = _actionButton('Evidências', Icons.photo_camera, const Color(0xFF3B82F6), () {
        Navigator.push(context, MaterialPageRoute(
          builder: (context) => EvidenceUploadScreen(bookingId: booking['id'] ?? '', booking: booking),
        ));
      });

      if (hasApprovedQuote) {
        return [
          evidenceButton,
          quoteButton,
          _actionButton('Finalizar', Icons.check_circle_rounded, const Color(0xFF00C977), () => _showFinishServiceDialog(booking)),
        ];
      }

      return [evidenceButton, quoteButton];
    }

    return [];
  }

  Widget _buildBottomActionBar(Map<String, dynamic> booking, bool isDarkMode, String statusFinal, String normalizedStatus) {
    final buttons = _getActionButtons(booking, isDarkMode, statusFinal, normalizedStatus);
    if (buttons.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: buttons.length <= 3
              ? Row(
                  children: List.generate(buttons.length, (i) {
                    final isLast = i == buttons.length - 1;
                    return Expanded(
                      flex: (buttons.length == 3 && isLast) ? 4 : 3,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: buttons[i],
                      ),
                    );
                  }),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: buttons.map((btn) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: btn,
                    )).toList(),
                  ),
                ),
        ),
      ),
    );
  }

  // ── Legacy _buildActionsCard (dead code — kept for reference) ───────

  Widget _buildActionsCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinal, String normalizedStatus) {
    // Verificar se realmente há botões de ação para exibir
    final hasFinalPrice = booking['final_price'] != null && (booking['final_price'] as num) > 0;
    final isPendingWorkshop = statusFinal == 'pendente_oficina' || statusFinal == 'pending' || normalizedStatus == 'pendente_oficina';
    final isConfirmed = statusFinal == 'confirmado' || normalizedStatus == 'confirmado';
    final isPendingClient = statusFinal == 'pendente_cliente' || normalizedStatus == 'pendente_cliente';
    final isEmAndamento = statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress';
    final isAppointmentDay = _isAppointmentDay(booking);
    
    // Determinar se há botões de ação reais (não apenas mensagens informativas)
    final hasRealActions = isPendingWorkshop || 
                          (isConfirmed && isAppointmentDay) ||  // Só exibir se for o dia do agendamento
                          isEmAndamento;
    
    // Se não há ações reais ou é pendente de cliente, não exibir card
    if (!hasRealActions || isPendingClient) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ações',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          
          // Lógica de botões baseada no status e se já foi enviado orçamento
          Builder(
            builder: (context) {
              // Verificar se já foi enviado um orçamento (final_price existe)
              final hasFinalPrice = booking['final_price'] != null && (booking['final_price'] as num) > 0;
              final isPendingClient = statusFinal == 'pendente_cliente' || normalizedStatus == 'pendente_cliente';
              final isConfirmed = statusFinal == 'confirmado' || normalizedStatus == 'confirmado';
              final isPendingWorkshop = statusFinal == 'pendente_oficina' || statusFinal == 'pending' || normalizedStatus == 'pendente_oficina';
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Botões para agendamento pendente (oficina precisa aprovar)
                  if (isPendingWorkshop) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          try {
                            final bookingId = booking['id']?.toString() ?? '';
                            if (bookingId.isEmpty) {
                              _showToast('ID do agendamento não encontrado.', isError: true);
                              return;
                            }

                            final result = await _apiService.confirmBooking(bookingId);

                            if (!mounted) return;

                            if (result['success'] == true) {
                              await _loadBookingDetails(forceRefresh: true);
                              _showToast('Agendamento aprovado com sucesso!');
                            } else {
                              _showToast(result['error']?.toString() ?? 'Erro ao aprovar agendamento.', isError: true);
                            }
                          } catch (e) {
                            if (!mounted) return;
                            _showToast('Erro: ${e.toString()}', isError: true);
                          }
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white, size: 22),
                        label: const Text(
                          'Aprovar',
                          style: TextStyle(
                            color: Colors.white, 
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 4,
                          shadowColor: const Color(0xFF00C977).withOpacity(0.4),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(booking),
                        icon: const Icon(Icons.cancel, color: Colors.red, size: 20),
                        label: const Text(
                          'Recusar',
                          style: TextStyle(
                            color: Colors.red, 
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.red.withOpacity(0.05),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSuggestTimeDialog(booking),
                        icon: const Icon(Icons.schedule, color: Colors.orange, size: 20),
                        label: const Text(
                          'Sugerir Outro Horário',
                          style: TextStyle(
                            color: Colors.orange, 
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          backgroundColor: Colors.orange.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                  
                  // Quando status é confirmado, mostrar opções baseadas no dia do agendamento
                  if (isConfirmed) ...[
                    Builder(
                      builder: (context) {
                        final isAppointmentDay = _isAppointmentDay(booking);
                        
                        // Se não for o dia do agendamento, não exibe nada (o card todo não será renderizado)
                        if (!isAppointmentDay) {
                          return const SizedBox.shrink();
                        }
                        
                        // É o dia do agendamento - mostrar as 2 opções
                        return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Título explicativo
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDarkMode 
                                      ? Colors.green[900]!.withOpacity(0.2) 
                                      : Colors.green[50]!,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.green[300]!.withOpacity(0.5),
                                    width: 2,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.check_circle_outline,
                                          color: Colors.green[700]!,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Escolha como deseja prosseguir',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: isDarkMode ? Colors.white : Colors.green[900]!,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                              
                              // Opção 1: Montar Orçamento (se ainda não foi enviado)
                              if (!hasFinalPrice) ...[
                                Builder(
                                  builder: (context) {
                                    final systemOrange = CupertinoColors.systemOrange.resolveFrom(context);
                                    final labelColor = CupertinoColors.label.resolveFrom(context);
                                    final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
                                    final cardBg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
                                    final headerBg = isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);

                                    return Container(
                                      decoration: BoxDecoration(
                                        color: cardBg,
                                        borderRadius: BorderRadius.circular(22),
                                        border: Border.all(
                                          color: systemOrange.withOpacity(isDarkMode ? 0.28 : 0.22),
                                          width: 1,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(isDarkMode ? 0.28 : 0.10),
                                            blurRadius: 26,
                                            offset: const Offset(0, 12),
                                          ),
                                        ],
                                      ),
                                      child: Column(
                                        children: [
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                            decoration: BoxDecoration(
                                              color: headerBg,
                                              borderRadius: const BorderRadius.only(
                                                topLeft: Radius.circular(22),
                                                topRight: Radius.circular(22),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Container(
                                                  width: 40,
                                                  height: 40,
                                                  decoration: BoxDecoration(
                                                    color: systemOrange.withOpacity(0.16),
                                                    borderRadius: BorderRadius.circular(12),
                                                  ),
                                                  child: Icon(
                                                    Icons.receipt_long_rounded,
                                                    color: systemOrange,
                                                    size: 22,
                                                  ),
                                                ),
                                                const SizedBox(width: 12),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment: CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        'OPÇÃO 1 • Orçamento prévio',
                                                        style: TextStyle(
                                                          color: secondaryLabel,
                                                          fontSize: 12,
                                                          fontWeight: FontWeight.w600,
                                                          letterSpacing: 0.2,
                                                        ),
                                                      ),
                                                      const SizedBox(height: 2),
                                                      Text(
                                                        'Montar orçamento',
                                                        style: TextStyle(
                                                          color: labelColor,
                                                          fontSize: 18,
                                                          fontWeight: FontWeight.w800,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(16),
                                            decoration: BoxDecoration(
                                              color: headerBg,
                                              borderRadius: const BorderRadius.only(
                                                bottomLeft: Radius.circular(22),
                                                bottomRight: Radius.circular(22),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Envie o orçamento antes de iniciar o serviço',
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: labelColor,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '• O cliente recebe o orçamento para aprovar\n• Após aprovação, você poderá iniciar o serviço\n• Ideal quando você já sabe o que precisa fazer',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: secondaryLabel,
                                                    height: 1.45,
                                                  ),
                                                ),
                                                const SizedBox(height: 14),
                                                SizedBox(
                                                  width: double.infinity,
                                                  child: ElevatedButton.icon(
                                                    onPressed: () async {
                                                      final result = await Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) => BuildQuoteScreen(bookingId: booking['id'] ?? ''),
                                                        ),
                                                      );
                                                      if (result == true) {
                                                        await _loadBookingDetails(forceRefresh: true);
                                                        await Future.delayed(const Duration(milliseconds: 800));
                                                        await _loadBookingDetails(forceRefresh: true);
                                                      }
                                                    },
                                                    icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 18),
                                                    label: const Text(
                                                      'Montar orçamento',
                                                      style: TextStyle(
                                                        color: Colors.white,
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 16,
                                                      ),
                                                    ),
                                                    style: ElevatedButton.styleFrom(
                                                      backgroundColor: systemOrange,
                                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                                      shape: RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.circular(14),
                                                      ),
                                                      elevation: 0,
                                                      shadowColor: Colors.transparent,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                            const SizedBox(height: 16),
                          ],
                          
                          // Opção 2: Iniciar Serviço (sempre disponível no dia, mesmo sem orçamento)
                          Container(
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(
                                color: CupertinoColors.systemBlue
                                    .resolveFrom(context)
                                    .withOpacity(isDarkMode ? 0.22 : 0.18),
                                width: 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(isDarkMode ? 0.28 : 0.10),
                                  blurRadius: 26,
                                  offset: const Offset(0, 12),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(22),
                                      topRight: Radius.circular(22),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 40,
                                        height: 40,
                                        decoration: BoxDecoration(
                                          color: CupertinoColors.systemBlue.resolveFrom(context).withOpacity(0.14),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.play_arrow_rounded,
                                          color: CupertinoColors.systemBlue.resolveFrom(context),
                                          size: 26,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'OPÇÃO 2 • Iniciar e orçar depois',
                                              style: TextStyle(
                                                color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              'Iniciar serviço',
                                              style: TextStyle(
                                                color: CupertinoColors.label.resolveFrom(context),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                                    borderRadius: const BorderRadius.only(
                                      bottomLeft: Radius.circular(22),
                                      bottomRight: Radius.circular(22),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        'Inicie o serviço agora e envie o orçamento ao finalizar',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: CupertinoColors.label.resolveFrom(context),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '• Você inicia o serviço imediatamente\n• Ao finalizar, monta o orçamento do que foi feito\n• O cliente aprova o orçamento final',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: CupertinoColors.secondaryLabel.resolveFrom(context),
                                          height: 1.45,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Builder(
                                        builder: (context) {
                                          final hasCheckIn = _hasCheckIn(booking);
                                          final checkInText = _formatCheckInAt(booking);
                                          final systemBlue = CupertinoColors.systemBlue.resolveFrom(context);
                                          final systemGreen = CupertinoColors.systemGreen.resolveFrom(context);
                                          final labelColor = CupertinoColors.label.resolveFrom(context);
                                          final secondaryLabel = CupertinoColors.secondaryLabel.resolveFrom(context);
                                          final tileBg = isDarkMode ? const Color(0xFF1C1C1E) : Colors.white;
                                          final tileBorder = CupertinoColors.separator
                                              .resolveFrom(context)
                                              .withOpacity(isDarkMode ? 0.25 : 0.16);
                                          final tileShadow = Colors.black.withOpacity(isDarkMode ? 0.22 : 0.07);
                                          final checkInAccent = hasCheckIn ? systemGreen : systemBlue;

                                          return Column(
                                            children: [
                                              // PASSO 1: Check-in
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: tileBg,
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: tileBorder),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: tileShadow,
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 26,
                                                          height: 26,
                                                          alignment: Alignment.center,
                                                          decoration: BoxDecoration(
                                                            color: checkInAccent.withOpacity(0.16),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            '1',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: checkInAccent,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            'Check-in do veículo',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w800,
                                                              color: labelColor,
                                                            ),
                                                          ),
                                                        ),
                                                        Icon(
                                                          hasCheckIn ? Icons.check_circle : Icons.info_outline,
                                                          size: 18,
                                                          color: checkInAccent,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      hasCheckIn
                                                          ? 'Check-in realizado${checkInText != null ? ' em $checkInText' : ''}.'
                                                          : 'Obrigatório para liberar o botão “Iniciar serviço”.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        height: 1.3,
                                                        color: secondaryLabel,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton.icon(
                                                        onPressed: hasCheckIn
                                                            ? null
                                                            : () async {
                                                                final bookingId = booking['id']?.toString() ?? '';
                                                                await _promptCheckInAndDo(bookingId);
                                                              },
                                                        icon: Icon(
                                                          hasCheckIn ? Icons.check_circle : Icons.directions_car,
                                                          color: hasCheckIn ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.white,
                                                          size: 18,
                                                        ),
                                                        label: Text(
                                                          hasCheckIn ? 'Check-in realizado' : 'Fazer check-in do veículo',
                                                          style: TextStyle(
                                                            color: hasCheckIn ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.white,
                                                            fontWeight: FontWeight.bold,
                                                          ),
                                                        ),
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: hasCheckIn ? (isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300) : systemBlue,
                                                          disabledBackgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade300,
                                                          foregroundColor: hasCheckIn ? (isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600) : Colors.white,
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                          elevation: hasCheckIn ? 0 : 0,
                                                          shadowColor: Colors.transparent,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const SizedBox(height: 14),

                                              // PASSO 2: Iniciar serviço (mesmo estilo do Check-in)
                                              Container(
                                                width: double.infinity,
                                                padding: const EdgeInsets.all(14),
                                                decoration: BoxDecoration(
                                                  color: tileBg,
                                                  borderRadius: BorderRadius.circular(18),
                                                  border: Border.all(color: tileBorder),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: tileShadow,
                                                      blurRadius: 14,
                                                      offset: const Offset(0, 8),
                                                    ),
                                                  ],
                                                ),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Row(
                                                      children: [
                                                        Container(
                                                          width: 26,
                                                          height: 26,
                                                          alignment: Alignment.center,
                                                          decoration: BoxDecoration(
                                                            color: systemGreen.withOpacity(0.16),
                                                            borderRadius: BorderRadius.circular(8),
                                                          ),
                                                          child: Text(
                                                            '2',
                                                            style: TextStyle(
                                                              fontWeight: FontWeight.bold,
                                                              color: systemGreen,
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(width: 10),
                                                        Expanded(
                                                          child: Text(
                                                            'Iniciar serviço',
                                                            style: TextStyle(
                                                              fontSize: 14,
                                                              fontWeight: FontWeight.w800,
                                                              color: labelColor,
                                                            ),
                                                          ),
                                                        ),
                                                        Icon(
                                                          hasCheckIn ? Icons.play_circle : Icons.lock_outline,
                                                          size: 18,
                                                          color: hasCheckIn ? systemGreen : secondaryLabel,
                                                        ),
                                                      ],
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Text(
                                                      hasCheckIn
                                                          ? 'Ao iniciar, o cliente receberá uma notificação de que o serviço começou.'
                                                          : 'Disponível após o check-in do veículo.',
                                                      style: TextStyle(
                                                        fontSize: 13,
                                                        height: 1.3,
                                                        color: secondaryLabel,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 10),
                                                    SizedBox(
                                                      width: double.infinity,
                                                      child: ElevatedButton(
                                                        onPressed: hasCheckIn
                                                            ? () async {
                                                                try {
                                                                  final bookingId = booking['id']?.toString() ?? '';
                                                                  if (bookingId.isEmpty) {
                                                                    _showToast('ID do agendamento não encontrado.', isError: true);
                                                                    return;
                                                                  }

                                                                  // Mostrar diálogo de confirmação
                                                                  final confirm = await showDialog<bool>(
                                                                    context: context,
                                                                    builder: (context) => AlertDialog(
                                                                      backgroundColor: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
                                                                      shape: RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.circular(20),
                                                                      ),
                                                                      title: Row(
                                                                        children: [
                                                                          const Icon(
                                                                            Icons.play_circle_outline,
                                                                            color: Color(0xFF00B4D8),
                                                                            size: 28,
                                                                          ),
                                                                          const SizedBox(width: 12),
                                                                          Expanded(
                                                                            child: Text(
                                                                              'Iniciar Serviço',
                                                                              style: TextStyle(
                                                                                fontSize: 20,
                                                                                fontWeight: FontWeight.bold,
                                                                                color: isDarkMode ? Colors.white : Colors.black87,
                                                                              ),
                                                                            ),
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      content: Column(
                                                                        mainAxisSize: MainAxisSize.min,
                                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                                        children: [
                                                                          Text(
                                                                            'Ao iniciar o serviço:',
                                                                            style: TextStyle(
                                                                              fontSize: 16,
                                                                              fontWeight: FontWeight.w600,
                                                                              color: isDarkMode ? Colors.white : Colors.black87,
                                                                            ),
                                                                          ),
                                                                          const SizedBox(height: 12),
                                                                          _buildInfoItem(
                                                                            'O cliente receberá uma notificação de que o serviço começou',
                                                                            Icons.notifications,
                                                                            isDarkMode,
                                                                          ),
                                                                          const SizedBox(height: 8),
                                                                          _buildInfoItem(
                                                                            'Ao finalizar o serviço, você montará o orçamento do que foi feito',
                                                                            Icons.receipt_long,
                                                                            isDarkMode,
                                                                          ),
                                                                        ],
                                                                      ),
                                                                      actions: [
                                                                        TextButton(
                                                                          onPressed: () => Navigator.pop(context, false),
                                                                          child: Text(
                                                                            'Cancelar',
                                                                            style: TextStyle(
                                                                              color: isDarkMode ? Colors.grey[400]! : Colors.grey[700]!,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                        ElevatedButton(
                                                                          onPressed: () => Navigator.pop(context, true),
                                                                          style: ElevatedButton.styleFrom(
                                                                            backgroundColor: systemGreen,
                                                                            shape: RoundedRectangleBorder(
                                                                              borderRadius: BorderRadius.circular(12),
                                                                            ),
                                                                            elevation: 0,
                                                                            shadowColor: Colors.transparent,
                                                                          ),
                                                                          child: const Text(
                                                                            'Confirmar',
                                                                            style: TextStyle(
                                                                              color: Colors.white,
                                                                              fontWeight: FontWeight.w600,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  );

                                                                  if (confirm != true) return;

                                                                  final result = await _apiService.startService(bookingId);

                                                                  if (!mounted) return;

                                                                  if (result['success'] == true) {
                                                                    await _loadBookingDetails(forceRefresh: true);
                                                                    _showToast('Serviço iniciado! O cliente foi notificado.');
                                                                  } else {
                                                                    _showToast(result['error']?.toString() ?? 'Erro ao iniciar serviço.', isError: true);
                                                                  }
                                                                } catch (e) {
                                                                  if (!mounted) return;
                                                                  _showToast('Erro: ${e.toString()}', isError: true);
                                                                }
                                                              }
                                                            : null,
                                                        style: ElevatedButton.styleFrom(
                                                          backgroundColor: systemGreen,
                                                          disabledBackgroundColor: CupertinoColors.systemGrey4.resolveFrom(context),
                                                          padding: const EdgeInsets.symmetric(vertical: 14),
                                                          shape: RoundedRectangleBorder(
                                                            borderRadius: BorderRadius.circular(14),
                                                          ),
                                                          elevation: 0,
                                                          shadowColor: Colors.transparent,
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: [
                                                            Icon(
                                                              Icons.play_arrow_rounded,
                                                              color: hasCheckIn
                                                                  ? Colors.white
                                                                  : CupertinoColors.systemGrey.resolveFrom(context),
                                                              size: 20,
                                                            ),
                                                            const SizedBox(width: 8),
                                                            Text(
                                                              'Iniciar serviço',
                                                              style: TextStyle(
                                                                color: hasCheckIn
                                                                    ? Colors.white
                                                                    : CupertinoColors.systemGrey.resolveFrom(context),
                                                                fontWeight: FontWeight.bold,
                                                                fontSize: 16,
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
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                            ],
                          );
                      },
                    ),
                  ],
                  
                  // Botão de iniciar serviço quando já tem orçamento aprovado (comportamento antigo mantido)
                  // Quando o cliente aprova o orçamento inicial, o status volta para "confirmado" e tem final_price
                  if (isConfirmed && hasFinalPrice && !isPendingClient && _isAppointmentDay(booking)) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bookingId = booking['id']?.toString() ?? '';
                              if (bookingId.isEmpty) {
                                _showToast('ID do agendamento não encontrado.', isError: true);
                                return;
                              }

                              if (!_hasCheckIn(booking)) {
                                await _promptCheckInAndDo(bookingId);
                                return;
                              }
                              
                              // Oficina inicia direto; cliente recebe notificação
                              final result = await _apiService.startService(bookingId);
                              
                              if (!mounted) return;
                              
                              if (result['success'] == true) {
                                await _loadBookingDetails(forceRefresh: true);
                                _showToast('Serviço iniciado! O cliente foi notificado.');
                              } else {
                                _showToast(result['error']?.toString() ?? 'Erro ao iniciar serviço.', isError: true);
                              }
                            } catch (e) {
                              if (!mounted) return;
                              _showToast('Erro: ${e.toString()}', isError: true);
                            }
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text(
                            'Iniciar Serviço',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: CupertinoColors.systemGreen.resolveFrom(context),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Botão de editar orçamento (quando já está em_andamento)
                  if (statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                onPressed: () async {
                  // Buscar items existentes do orçamento
                  final existingItems = booking['quote_items'] as List<dynamic>?;
                  final existingDiagnostic = int.tryParse(booking['diagnostic_value']?.toString() ?? '');
                  
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BuildQuoteScreen(
                        bookingId: booking['id'] ?? '',
                        existingItems: existingItems?.map((item) => {
                          'description': item['description'] ?? '',
                          'quantity': item['quantity'] ?? 1,
                          'unit_price': item['unit_price'] ?? 0,
                        }).toList(),
                        existingDiagnosticValue: existingDiagnostic,
                        isEditMode: true, // Modo de edição
                      ),
                    ),
                  );
                  
                  if (result == true) {
                    await _loadBookingDetails();
                  }
                },
                icon: const Icon(Icons.edit_note_rounded, color: Colors.orange),
                label: const Text(
                  'Editar orçamento',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w700),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.orange.withOpacity(0.8), width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: Colors.orange.withOpacity(0.06),
                ),
                      ),
                    ),
                  
                  // Botão de finalizar serviço (quando já está em_andamento)
                  if (statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress')
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => _showFinishServiceDialog(booking),
                          icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                          label: const Text(
                            'Finalizar serviço',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00C977),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                        ),
                      ),
                    ),
                  
                  // Botão de upload de evidências (quando serviço está em andamento)
                  if (statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress') ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EvidenceUploadScreen(
                                bookingId: booking['id'] ?? '',
                                booking: booking,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.photo_camera, color: Color(0xFF00C977)),
                        label: const Text(
                          'Upload de Evidências',
                          style: TextStyle(color: Color(0xFF00C977), fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF00C977)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return Colors.orange;
      case 'confirmed':
      case 'confirmado':
        return Colors.blue;
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return Colors.purple;
      case 'pendente_cliente':
        return Colors.amber.shade700;
      case 'finalizado_aguardando_pagamento':
        return Colors.blue.shade700;
      case 'pago':
      case 'paid':
      case 'completed':
      case 'concluido':
      case 'concluído':
        return Colors.green;
      case 'cancelled':
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    final normalizedStatus = status.toLowerCase().trim();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return 'Aguardando Confirmação';
      case 'confirmed':
      case 'confirmado':
        return 'Confirmado';
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return 'Em Andamento';
      case 'pendente_cliente':
      case 'pending_customer':
        return 'Aguardando Cliente';
      case 'awaiting_quote_approval':
      case 'aguardando_aprovacao_orcamento':
        return 'Orçamento - Aguardando Aprovação';
      case 'awaiting_service_start':
      case 'aguardando_autorizacao_inicio':
        return 'Aguardando Autorização de Início';
      case 'vehicle_at_workshop':
      case 'veiculo_na_oficina':
        return 'Veículo na Oficina';
      case 'awaiting_finalization_approval':
      case 'aguardando_aprovacao_finalizacao':
        return 'Aguardando Aprovação de Finalização';
      case 'finalizado_aguardando_pagamento':
      case 'awaiting_payment':
      case 'aguardando_pagamento':
        return 'Aguardando Pagamento';
      case 'pago':
      case 'paid':
        return 'Pago';
      case 'completed':
      case 'concluido':
      case 'concluído':
        return 'Concluído';
      case 'cancelled':
      case 'cancelado':
        return 'Cancelado';
      case 'rejected':
      case 'rejeitado':
        return 'Rejeitado';
      case 'in_dispute':
      case 'em_disputa':
        return 'Em Disputa';
      default:
        // Formatar o status original de forma legível se não for reconhecido
        final formatted = status
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
        return formatted.isEmpty ? 'Status Desconhecido' : formatted;
    }
  }

  String _formatDate(dynamic dateTime) {
    if (dateTime == null) return 'Data não informada';
    
    try {
      final date = dateTime is String ? DateTime.parse(dateTime) : dateTime as DateTime;
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }

  String _formatTime(dynamic dateTime) {
    if (dateTime == null) return 'Hora não informada';
    
    try {
      final date = dateTime is String ? DateTime.parse(dateTime) : dateTime as DateTime;
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return 'Hora inválida';
    }
  }

  bool _hasCustomerUploads(Map<String, dynamic> booking) {
    final uploads = booking['customer_uploads'] ?? booking['customerUploads'];
    
    if (uploads == null) {
      return false;
    }
    
    if (uploads is List) {
      return uploads.isNotEmpty;
    }
    
    if (uploads is String) {
      try {
        final parsed = json.decode(uploads);
        if (parsed is List) {
          return parsed.isNotEmpty;
        }
      } catch (e) {
        return false;
      }
    }
    
    return false;
  }

  List<dynamic> _getCustomerUploadsList(Map<String, dynamic> booking) {
    final uploads = booking['customer_uploads'] ?? booking['customerUploads'];
    if (uploads == null) return [];
    
    if (uploads is List) {
      return uploads;
    }
    
    if (uploads is String) {
      try {
        final parsed = json.decode(uploads);
        if (parsed is List) {
          return parsed;
        }
      } catch (_) {
        return [];
      }
    }
    
    return [];
  }

  Widget _buildCustomerUploadsCard(Map<String, dynamic> booking, bool isDarkMode) {
    final uploads = _getCustomerUploadsList(booking);
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.photo_library,
                color: isDarkMode ? Colors.white : Colors.black87,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Imagens Enviadas pelo Cliente',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (uploads.isEmpty)
            Text(
              'Nenhuma imagem enviada',
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.0,
              ),
              itemCount: uploads.length,
              itemBuilder: (context, index) {
                final upload = uploads[index];
                // IMPORTANTE: Extrair URL de diferentes formatos possíveis
                String? url;
                
                // Debug: logar estrutura do upload
                debugPrint('🔍 [BookingDetail] Upload[$index] tipo: ${upload.runtimeType}, valor: ${upload.toString().substring(0, upload.toString().length > 200 ? 200 : upload.toString().length)}');
                
                if (upload is Map) {
                  // Debug: logar todas as chaves do Map
                  debugPrint('🔍 [BookingDetail] Upload[$index] chaves: ${upload.keys.toList()}');
                  
                  // Priorizar signed_url, depois url, depois s3_url
                  url = (upload['signed_url'] ?? upload['url'] ?? upload['s3_url'] ?? upload['image_url'] ?? '').toString();
                  
                  // Se ainda não tem URL, tentar extrair de campos aninhados
                  if (url.isEmpty) {
                    final nestedUrl = upload['image']?['url'] ?? upload['file_url'] ?? upload['key'];
                    url = nestedUrl?.toString();
                    debugPrint('🔍 [BookingDetail] Tentando extrair URL de campos aninhados: $nestedUrl');
                  }
                  
                  // Se tem key mas não tem URL, pode ser que precise gerar URL assinada
                  // Mas isso deve ser feito no backend, então apenas logar para debug
                  if ((url == null || url.isEmpty) && upload['key'] != null) {
                    debugPrint('⚠️ [BookingDetail] Upload tem key mas não tem URL: ${upload['key']}');
                  }
                } else if (upload is String) {
                  url = upload;
                  debugPrint('🔍 [BookingDetail] Upload é string direta: ${url.substring(0, url.length > 100 ? 100 : url.length)}...');
                }
                
                // VALIDAÇÃO CRÍTICA: URL deve começar com http:// ou https://
                // Se não for uma URL válida, não podemos usar
                if (url != null && url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
                  debugPrint('⚠️ [BookingDetail] URL inválida (não é http/https): $url');
                  debugPrint('⚠️ [BookingDetail] Upload completo: $upload');
                  url = null; // Invalidar URL
                }
                
                // Debug: logar URL extraída
                if (url != null && url.isNotEmpty) {
                  debugPrint('🖼️ [BookingDetail] Carregando imagem: ${url.substring(0, url.length > 100 ? 100 : url.length)}...');
                } else {
                  debugPrint('⚠️ [BookingDetail] Upload sem URL válida: $upload');
                }
                
                if (url == null || url.isEmpty) {
                  return Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.broken_image,
                        color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                      ),
                    ),
                  );
                }
                
                return GestureDetector(
                  onTap: () {
                    if (url != null && url.isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _ImageFullScreen(url: url!),
                        ),
                      );
                    }
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      httpHeaders: {
                        // IMPORTANTE: Adicionar headers para evitar problemas de CORS
                        'Accept': 'image/*',
                      },
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00C977)),
                        ),
                      ),
                      errorWidget: (context, url, error) {
                        // Debug: logar erro de carregamento
                        debugPrint('❌ [BookingDetail] Erro ao carregar imagem: $url');
                        debugPrint('❌ [BookingDetail] Erro: $error');
                        return Container(
                          decoration: BoxDecoration(
                            color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.broken_image,
                                color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
                                size: 32,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Imagem não disponível',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDarkMode ? Colors.grey[500] : Colors.grey[600],
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

// Widget para exibir imagem em tela cheia
class _ImageFullScreen extends StatelessWidget {
  final String url;

  const _ImageFullScreen({required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Center(
              child: Icon(
                Icons.broken_image,
                color: Colors.white,
                size: 64,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
