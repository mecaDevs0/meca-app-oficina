import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
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

  Future<void> _loadBookingDetails() async {
    setState(() => _loading = true);
    
    try {
      final bookingId = widget.booking['id']?.toString() ?? '';
      
      if (bookingId.isNotEmpty) {
        final result = await _apiService.getBookingDetails(bookingId);
        
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
                    
                    // Informações do cliente
                    _buildInfoCard(
                      'Informações do Cliente',
                      [
                        _buildInfoRow('Nome', booking['customer_name'] ?? 'Não informado', Icons.person),
                        _buildInfoRow('Telefone', booking['customer_phone'] ?? 'Não informado', Icons.phone),
                        _buildInfoRow('Email', booking['customer_email'] ?? 'Não informado', Icons.email),
                      ],
                      isDarkMode,
                    ),
                    
                    // Informações do veículo
                    _buildInfoCard(
                      'Informações do Veículo',
                      [
                        _buildInfoRow('Modelo', booking['vehicle_info'] ?? 'Não informado', Icons.directions_car),
                        _buildInfoRow('Placa', booking['vehicle_plate'] ?? 'Não informada', Icons.confirmation_number),
                      ],
                      isDarkMode,
                    ),
                    
                    // Informações do agendamento
                    _buildInfoCard(
                      'Informações do Agendamento',
                      [
                        // IMPORTANTE: Adicionar modelo do veículo na seção de Informações do Agendamento
                        if (booking['vehicle_info'] != null && booking['vehicle_info'].toString().trim().isNotEmpty)
                          _buildInfoRow('Modelo', booking['vehicle_info'], Icons.directions_car),
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
                    
                    // Card informativo sobre situação atual
                    _buildStatusInfoCard(booking, isDarkMode, normalizedStatus),
                    
                    // PASSO 15: Card de informações de pagamento (se pago)
                    if ((statusFinal == 'pago' || statusFinal == 'paid' || statusFinal == 'completed') && _paymentData != null)
                      _buildPaymentInfoCard(booking, isDarkMode),
                    
                    // Ações
                    _buildActionsCard(booking, isDarkMode, statusFinal, normalizedStatus),
                    
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

  Future<void> _showFinishServiceDialog(Map<String, dynamic> booking) async {
    // Buscar items existentes do orçamento (se houver)
    final existingItems = booking['quote_items'] as List<dynamic>?;
    final existingDiagnostic = booking['diagnostic_value'] as int?;
    
    // Navegar para tela de montar orçamento final
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
          isEditMode: false,
          isFinishMode: true, // Modo de finalização
        ),
      ),
    );
    
    if (result == true) {
      // A BuildQuoteScreen já chamou finishService, apenas recarregar detalhes
      await _loadBookingDetails();
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro: ID do agendamento não encontrado.'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      
        final apiResult = await _apiService.rejectBooking(
        bookingId,
          result,
      );
      
      if (!mounted) return;
      
        if (apiResult['success'] == true) {
        await _loadBookingDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Agendamento recusado com sucesso. O cliente foi notificado.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(apiResult['error']?.toString() ?? 'Erro ao recusar agendamento.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      }
    }
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
                              final picked = await showTimePicker(
                                context: context,
                                initialTime: selectedTime ?? TimeOfDay.now(),
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
                          final picked = await showTimePicker(
                            context: context,
                            initialTime: selectedTime ?? TimeOfDay.now(),
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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Erro: ID do agendamento não encontrado.'),
                backgroundColor: Colors.red,
              ),
            );
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
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(apiResult['error']?.toString() ?? 'Erro ao sugerir novo horário.'),
                backgroundColor: Colors.red,
              ),
            );
          }
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${e.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      // Dispose dos controllers apenas após processar o resultado
      reasonController.dispose();
      dateController.dispose();
      timeController.dispose();
    }
  }

  Widget _buildStatusInfoCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinal) {
    String title = '';
    String description = '';
    String nextStep = '';
    IconData icon = Icons.info;
    Color cardColor = Colors.blue.shade50;
    Color borderColor = Colors.blue.shade200;
    Color iconColor = Colors.blue.shade700;
    
    if (statusFinal == 'pending' || statusFinal == 'pendente_oficina' || statusFinal == 'pendente') {
      title = 'Aguardando Sua Aprovação';
      description = 'O cliente solicitou este agendamento. Você precisa aprovar, recusar ou sugerir um novo horário.';
      nextStep = 'Use os botões abaixo para responder ao cliente.';
      icon = Icons.pending_actions;
      cardColor = Colors.orange.shade50;
      borderColor = Colors.orange.shade200;
      iconColor = Colors.orange.shade700;
    } else if (statusFinal == 'confirmado' || statusFinal == 'confirmed') {
      title = 'Agendamento Confirmado ✓';
      description = 'Ótimo! Você aprovou este agendamento. O próximo passo é enviar um orçamento para o cliente.';
      nextStep = '📝 IMPORTANTE: Clique no botão "Enviar Orçamento" abaixo para informar o valor do serviço ao cliente. Após o cliente aprovar, você poderá iniciar o serviço.';
      icon = Icons.check_circle;
      cardColor = Colors.blue.shade50;
      borderColor = Colors.blue.shade200;
      iconColor = Colors.blue.shade700;
    } else if (statusFinal == 'pendente_cliente') {
      title = 'Aguardando Aprovação do Cliente ⏳';
      description = 'Você enviou o orçamento! Agora é a vez do cliente analisar e aprovar o valor.';
      nextStep = '⏰ Aguarde a aprovação do cliente. Quando ele aprovar, você receberá uma notificação e poderá iniciar o serviço.';
      icon = Icons.hourglass_empty;
      cardColor = Colors.amber.shade50;
      borderColor = Colors.amber.shade200;
      iconColor = Colors.amber.shade800;
    } else if (statusFinal == 'in_progress' || statusFinal == 'started' || statusFinal == 'em_andamento') {
      title = 'Serviço em Andamento 🔧';
      description = 'O cliente aprovou o orçamento e você iniciou o serviço. Continue realizando o trabalho.';
      nextStep = '📸 Dica: Tire fotos do serviço durante a execução usando o botão "Enviar Provas". Quando terminar, clique em "Finalizar Serviço" para concluir.';
      icon = Icons.build_circle;
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      iconColor = Colors.green.shade700;
    } else if (statusFinal == 'finalizado_aguardando_pagamento' || statusFinal == 'finalizado') {
      title = 'Aguardando Pagamento';
      description = 'O serviço foi finalizado e o cliente aprovou o orçamento. Aguardando pagamento.';
      nextStep = 'O cliente realizará o pagamento. Você será notificado quando o pagamento for confirmado.';
      icon = Icons.payments;
      cardColor = Colors.cyan.shade50;
      borderColor = Colors.cyan.shade200;
      iconColor = Colors.cyan.shade700;
    } else if (statusFinal == 'pago' || statusFinal == 'paid' || statusFinal == 'completed') {
      title = 'Pagamento Confirmado';
      description = 'O pagamento foi realizado com sucesso! O serviço está concluído.';
      nextStep = 'O cliente pode avaliar o serviço. Verifique o pagamento na sua conta PagBank.';
      icon = Icons.done_all;
      cardColor = Colors.green.shade50;
      borderColor = Colors.green.shade200;
      iconColor = Colors.green.shade700;
    }
    
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? cardColor.withOpacity(0.1) : cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : iconColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
              height: 1.4,
            ),
          ),
          if (nextStep.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.arrow_forward, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      nextStep,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: iconColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
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

  Widget _buildActionsCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinal, String normalizedStatus) {
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Erro: ID do agendamento não encontrado.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            
                            final result = await _apiService.confirmBooking(bookingId);
                            
                            if (!mounted) return;
                            
                            if (result['success'] == true) {
                              await _loadBookingDetails();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✅ Agendamento aprovado com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['error']?.toString() ?? 'Erro ao aprovar agendamento.'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          } catch (e) {
                            if (!mounted) return;
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Erro: ${e.toString()}'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.check_circle, color: Colors.white),
                        label: const Text(
                          'Aprovar',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00C977),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showRejectDialog(booking),
                        icon: const Icon(Icons.cancel, color: Colors.red),
                        label: const Text(
                          'Recusar',
                          style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _showSuggestTimeDialog(booking),
                        icon: const Icon(Icons.schedule, color: Colors.orange),
                        label: const Text(
                          'Sugerir Outro Horário',
                          style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.orange),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                  
                  // Botão de montar/enviar orçamento (quando status é confirmado E ainda não foi enviado orçamento)
                  if (isConfirmed && !hasFinalPrice)
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
                            await _loadBookingDetails();
                          }
                        },
                        icon: const Icon(Icons.send, color: Colors.white),
                        label: const Text(
                          '📝 Montar Orçamento',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  
                  // Botão de iniciar serviço (quando status é confirmado E já foi enviado e aprovado orçamento)
                  // Quando o cliente aprova o orçamento inicial, o status volta para "confirmado" e tem final_price
                  if (isConfirmed && hasFinalPrice && !isPendingClient)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            try {
                              final bookingId = booking['id']?.toString() ?? '';
                              if (bookingId.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Erro: ID do agendamento não encontrado.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              
                              final result = await _apiService.startService(bookingId);
                              
                              if (!mounted) return;
                              
                              if (result['success'] == true) {
                                await _loadBookingDetails();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('✅ Serviço iniciado com sucesso! O cliente foi notificado.'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(result['error']?.toString() ?? 'Erro ao iniciar serviço.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erro: ${e.toString()}'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          label: const Text(
                            '▶️ Iniciar Serviço',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00B4D8),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Botão de editar orçamento (quando já está em_andamento)
                  if (statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress')
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                onPressed: () async {
                  // Buscar items existentes do orçamento
                  final existingItems = booking['quote_items'] as List<dynamic>?;
                  final existingDiagnostic = booking['diagnostic_value'] as int?;
                  
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
                icon: const Icon(Icons.edit, color: Colors.orange),
                label: const Text(
                  '✏️ Editar Orçamento',
                  style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.orange, width: 2),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                            '✅ Finalizar Serviço',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00C977),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                            ),
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
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return 'Pendente';
      case 'confirmed':
      case 'confirmado':
        return 'Confirmado';
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return 'Em Andamento';
      case 'pendente_cliente':
        return 'Aguardando Aprovação do Cliente';
      case 'finalizado_aguardando_pagamento':
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
      default:
        return status.isNotEmpty ? status : 'Desconhecido';
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
                final url = (upload['url'] ?? upload['signed_url'] ?? '').toString();
                
                if (url.isEmpty) {
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
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => _ImageFullScreen(url: url),
                      ),
                    );
                  },
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(color: Color(0xFF00C977)),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
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
                      ),
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
