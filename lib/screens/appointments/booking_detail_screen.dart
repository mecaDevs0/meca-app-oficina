import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../services/api_service.dart';
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
  bool _loading = true;
  bool _generatingPaymentLink = false;

  void _showSnackBar(SnackBar snackBar) {
    if (!mounted) return;
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;
    messenger.showSnackBar(snackBar);
  }

  bool _hasCheckIn(Map<String, dynamic> booking) {
    final v = booking['check_in_at'] ?? booking['checkInAt'] ?? booking['check_in'];
    return v != null && v.toString().trim().isNotEmpty;
  }

  Future<void> _promptCheckInAndDo(String bookingId) async {
    if (bookingId.trim().isEmpty) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Check-in obrigatório'),
        content: const Text(
          'Para iniciar o serviço, registre a chegada do veículo (check-in) primeiro.',
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
      await _loadBookingDetails();
      _showSnackBar(const SnackBar(
        content: Text('✅ Check-in realizado! Agora você já pode iniciar o serviço.'),
        backgroundColor: Colors.green,
      ));
    } else {
      _showSnackBar(SnackBar(
        content: Text(result['error']?.toString() ?? 'Não foi possível fazer o check-in.'),
        backgroundColor: Colors.red,
      ));
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
    // Recarregar quando o app voltar ao foco (ex: cliente aprovou orçamento em outro app)
    if (state == AppLifecycleState.resumed) {
      _loadBookingDetails();
    }
  }

  Future<void> _loadBookingDetails() async {
    setState(() => _loading = true);
    
    try {
      // Carregar detalhes completos do agendamento incluindo customer_uploads
      final bookingId = widget.booking['id']?.toString() ?? '';
      
      if (bookingId.isNotEmpty) {
        final result = await _apiService.getBookingDetails(bookingId);
        
        if (result['success'] == true && result['data'] != null) {
          final data = Map<String, dynamic>.from(result['data']);
          
          setState(() {
            _bookingDetails = data;
          });
        } else {
          if (result['unauthorized'] == true) {
            // Token expirado - redirecionar para login
            // TODO: Implementar redirecionamento para login se necessário
          }
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

    // SEMPRE usar o status de _bookingDetails (da API) se disponível, senão usar do widget
    final statusFromDetails = (_bookingDetails?['status'] ?? '').toString().toLowerCase().trim();
    final statusFromWidget = (widget.booking['status'] ?? '').toString().toLowerCase().trim();
    final statusFinal = statusFromDetails.isNotEmpty ? statusFromDetails : statusFromWidget;

    // CRITICAL: Se service_start_pending = true e não há orçamento, forçar status para aguardando_autorizacao_inicio
    // Isso garante que a UI mostre a mensagem correta mesmo se a API retornar pendente_cliente (compatibilidade)
    final booking = Map<String, dynamic>.from(_bookingDetails ?? widget.booking);
    final serviceStartPending = booking['service_start_pending'] == true || booking['service_start_pending'] == 'true';
    final hasQuote = (booking['final_price'] != null && (booking['final_price'] is num ? booking['final_price'] > 0 : false)) ||
                    (booking['quote_items'] != null && booking['quote_items'] is List && (booking['quote_items'] as List).isNotEmpty);

    // Se é início de serviço sem orçamento, forçar status correto
    final correctedStatus = (serviceStartPending && !hasQuote && (statusFinal == 'pendente_cliente' || statusFinal == 'pending_customer'))
        ? 'aguardando_autorizacao_inicio'
        : statusFinal;

    // Normalizar status para garantir comparação correta
    final normalizedStatus = correctedStatus == 'confirmed' ? 'confirmado' : 
                            correctedStatus == 'confirmado' ? 'confirmado' :
                            correctedStatus;

    final isAwaitingServiceStart = correctedStatus == 'aguardando_autorizacao_inicio' ||
        correctedStatus == 'awaiting_service_start' ||
        (serviceStartPending && !hasQuote);
    final isAwaitingQuoteApproval = (correctedStatus == 'aguardando_aprovacao_orcamento' ||
        correctedStatus == 'awaiting_quote_approval') && hasQuote;

    // Debug: verificar status
    debugPrint('🔍 [Appointments Detail] Status final: $normalizedStatus (original: $statusFinal, from details: $statusFromDetails, from widget: $statusFromWidget)');

    booking['status'] = correctedStatus; // Usar status corrigido se necessário

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
                            color: _getStatusColor(correctedStatus).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _getStatusText(correctedStatus),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _getStatusColor(correctedStatus),
                            ),
                          ),
                        ),
                        // Aviso especial para status aguardando aprovação
                        // CRITICAL: Verificar se é orçamento OU início de serviço usando novos estados
                        // IMPORTANTE: Verificar service_start_pending PRIMEIRO para evitar mostrar mensagem de orçamento quando é início de serviço
                        // Usar correctedStatus (já foi corrigido acima se necessário)
                        // CRITICAL: Se é início de serviço (service_start_pending = true e não há orçamento), mostrar card azul
                        if (isAwaitingServiceStart) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.blue.shade200),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade800),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'O cliente foi notificado de que o serviço começou.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.blue.shade900,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        // Se é aguardando aprovação de orçamento (e NÃO é início de serviço), mostrar card amarelo
                        if (isAwaitingQuoteApproval && !isAwaitingServiceStart) ...[
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
                  
                  // Informações do veículo (marca/modelo da API: vehicle_brand, vehicle_model)
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
                      _buildInfoRow('Hora', _formatTime(booking['appointment_date']), Icons.access_time),
                      if (booking['estimated_price'] != null)
                        _buildInfoRow('Valor Estimado', 'R\$ ${booking['estimated_price'].toStringAsFixed(2)}', Icons.attach_money),
                    ],
                    isDarkMode,
                  ),
                  
                  // Observações
                  if (booking['customer_notes'] != null && booking['customer_notes'].isNotEmpty)
                    _buildInfoCard(
                      'Observações do Cliente',
                      [
                        _buildInfoRow('', booking['customer_notes'], Icons.note),
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
                  _buildStatusInfoCard(booking, isDarkMode, correctedStatus),
                  
                  // Ações
                  _buildActionsCard(booking, isDarkMode, correctedStatus, normalizedStatus),
                  
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

  Future<void> _showFinishServiceDialog(Map<String, dynamic> booking) async {
    final priceController = TextEditingController();
    final notesController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Serviço'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Informe o valor final do serviço e observações (opcional):'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Valor Final (R\$)',
                    prefixText: 'R\$ ',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Informe o valor final';
                    }
                    final price = double.tryParse(value.replaceAll(',', '.'));
                    if (price == null || price <= 0) {
                      return 'Valor inválido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Observações (opcional)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00C977),
            ),
            child: const Text('Finalizar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final priceCents = (price * 100).round();
    final notes = notesController.text.trim().isEmpty ? null : notesController.text.trim();
    
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
      
      final result = await _apiService.finishService(
        bookingId,
        finalPriceCents: priceCents,
        notes: notes,
      );
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        await _loadBookingDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Serviço finalizado com sucesso! O cliente receberá uma notificação para aprovar o orçamento.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error']?.toString() ?? 'Erro ao finalizar serviço.'),
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

  Future<void> _showSendQuoteDialog(Map<String, dynamic> booking) async {
    final priceController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Enviar Orçamento'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Informe o valor do orçamento que será enviado ao cliente:'),
              const SizedBox(height: 16),
              TextFormField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Valor (R\$)',
                  prefixText: 'R\$ ',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Informe o valor';
                  }
                  final price = double.tryParse(value.replaceAll(',', '.'));
                  if (price == null || price <= 0) {
                    return 'Valor inválido';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(context).pop(true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
            ),
            child: const Text('Enviar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    
    if (result != true) return;
    
    final price = double.tryParse(priceController.text.replaceAll(',', '.')) ?? 0;
    if (price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Valor inválido'), backgroundColor: Colors.red),
      );
      return;
    }
    
    final priceCents = (price * 100).round();
    
    try {
      final result = await _apiService.sendQuote(booking['id'] ?? '', finalPriceCents: priceCents);
      
      if (!mounted) return;
      
      if (result['success'] == true) {
        await _loadBookingDetails();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orçamento enviado com sucesso! O cliente receberá uma notificação.'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao enviar orçamento'),
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

  /// Card de status: apenas uma frase curta e didática (sem título/subtítulo). Menos texto = app mais simples.
  Widget _buildStatusInfoCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinalRaw) {
    final serviceStartPending = booking['service_start_pending'] == true || booking['service_start_pending'] == 'true';
    final hasQuote = (booking['final_price'] != null && (booking['final_price'] is num ? booking['final_price'] > 0 : false)) ||
        (booking['quote_items'] != null && booking['quote_items'] is List && (booking['quote_items'] as List).isNotEmpty);
    final statusFinal = (serviceStartPending && !hasQuote && (statusFinalRaw == 'pendente_cliente' || statusFinalRaw == 'pending_customer'))
        ? 'aguardando_autorizacao_inicio'
        : statusFinalRaw;

    String phrase = '';
    if (statusFinal == 'pending' || statusFinal == 'pendente_oficina' || statusFinal == 'pendente') {
      phrase = 'O cliente solicitou. Aprove, recuse ou sugira outro horário.';
    } else if (statusFinal == 'confirmado' || statusFinal == 'confirmed') {
      phrase = 'Escolha como deseja prosseguir.';
    } else if (statusFinal == 'aguardando_aprovacao_orcamento' || statusFinal == 'awaiting_quote_approval' || statusFinal == 'pendente_cliente') {
      if (serviceStartPending && !hasQuote) {
        phrase = 'Você iniciou o serviço. Aguarde o cliente confirmar.';
      } else if (hasQuote) {
        phrase = 'Orçamento enviado. Aguarde a aprovação do cliente.';
      } else {
        phrase = 'Aguarde a resposta do cliente.';
      }
    } else if (statusFinal == 'aguardando_autorizacao_inicio' || statusFinal == 'awaiting_service_start') {
      phrase = 'Você iniciou o serviço. Aguarde o cliente confirmar.';
    } else if (statusFinal == 'veiculo_na_oficina' || statusFinal == 'vehicle_at_workshop') {
      phrase = 'Veículo na oficina. Inicie o serviço ou envie orçamento.';
    } else if (statusFinal == 'aguardando_aprovacao_finalizacao' || statusFinal == 'awaiting_finalization_approval') {
      phrase = 'Aguarde o cliente aprovar a finalização.';
    } else if (statusFinal == 'em_disputa' || statusFinal == 'in_dispute') {
      phrase = 'Há uma pendência. Entre em contato com o cliente.';
    } else if (statusFinal == 'in_progress' || statusFinal == 'started' || statusFinal == 'em_andamento') {
      phrase = 'Serviço em andamento. Ao finalizar, envie o orçamento final.';
    } else if (statusFinal == 'finalizado_aguardando_pagamento' || statusFinal == 'finalizado') {
      phrase = 'Serviço finalizado. Aguardando pagamento do cliente.';
    } else if (statusFinal == 'pago' || statusFinal == 'paid' || statusFinal == 'completed') {
      phrase = 'Pagamento confirmado. Serviço concluído.';
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

  Widget _buildActionsCard(Map<String, dynamic> booking, bool isDarkMode, String statusFinal, String normalizedStatus) {
    final isConfirmado = statusFinal == 'confirmado' || normalizedStatus == 'confirmado';
    final isAguardandoPagamento = statusFinal == 'finalizado_aguardando_pagamento' ||
        statusFinal == 'aguardando_pagamento' ||
        statusFinal == 'awaiting_payment';
    final hasAnyButton = isConfirmado || isAguardandoPagamento;
    if (!hasAnyButton) {
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
          
          // Botão de enviar orçamento (quando status é confirmado)
          if (statusFinal == 'confirmado' || normalizedStatus == 'confirmado')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showSendQuoteDialog(booking),
                icon: const Icon(Icons.send, color: Colors.white),
                label: const Text(
                  'Enviar Orçamento',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          
          if (statusFinal == 'confirmado' || normalizedStatus == 'confirmado') ...[
            const SizedBox(height: 12),
            // Botão para iniciar serviço diretamente (se não houver orçamento inicial)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Chamar API para iniciar serviço diretamente
                  try {
                    final bookingId = booking['id']?.toString() ?? '';
                    if (bookingId.isEmpty) {
                      _showSnackBar(
                        const SnackBar(
                          content: Text('Erro: ID do agendamento não encontrado.'),
                          backgroundColor: Colors.red,
                        ),
                      );
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
                      await _loadBookingDetails();
                      _showSnackBar(
                        const SnackBar(
                          content: Text('✅ Serviço iniciado! O cliente foi notificado.'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } else {
                      _showSnackBar(
                        SnackBar(
                          content: Text(result['error']?.toString() ?? 'Erro ao iniciar serviço.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    _showSnackBar(
                      SnackBar(
                        content: Text('Erro: ${e.toString()}'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow, color: Colors.white),
                label: const Text(
                  'Iniciar Serviço',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          ],
          
          // Botão de finalizar serviço (quando já está em_andamento)
          if (statusFinal == 'em_andamento' || statusFinal == 'in_progress' || normalizedStatus == 'em_andamento' || normalizedStatus == 'in_progress')
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showFinishServiceDialog(booking),
                icon: const Icon(Icons.check_circle, color: Colors.white),
                label: const Text(
                  'Finalizar Serviço',
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
          
          // Botão de upload de evidências (quando serviço está completo)
          if (booking['status'] == 'completed' || booking['status'] == 'concluido')
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

          // Botão de Link de Pagamento (quando aguardando pagamento)
          if (isAguardandoPagamento) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _generatingPaymentLink ? null : () => _generatePaymentLink(booking),
                icon: _generatingPaymentLink
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.link, color: Colors.white),
                label: Text(
                  _generatingPaymentLink ? 'Gerando...' : 'Link de Pagamento',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
          ],
        ],
      ),
    );
  }

  Future<void> _generatePaymentLink(Map<String, dynamic> booking) async {
    final bookingId = booking['id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    setState(() => _generatingPaymentLink = true);
    try {
      final result = await _apiService.post('/bookings/$bookingId/payment-link', {});
      if (!mounted) return;

      if (result['success'] == true && result['data'] != null) {
        final link = result['data']['payment_link'] ?? '';
        if (link.isNotEmpty) {
          await Clipboard.setData(ClipboardData(text: link));
          _showSnackBar(const SnackBar(
            content: Text('Link copiado! Envie ao cliente.'),
            backgroundColor: Colors.green,
          ));
        }
      } else {
        _showSnackBar(SnackBar(
          content: Text(result['error']?.toString() ?? 'Erro ao gerar link'),
          backgroundColor: Colors.red,
        ));
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar(SnackBar(
        content: Text('Erro: ${e.toString()}'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _generatingPaymentLink = false);
    }
  }

  Color _getStatusColor(String status) {
    final normalizedStatus = status.toLowerCase();
    switch (normalizedStatus) {
      case 'pending':
      case 'pendente':
      case 'pendente_oficina':
        return const Color(0xFFFF9800);
      case 'confirmed':
      case 'confirmado':
        return const Color(0xFF00C977);
      case 'in_progress':
      case 'em_andamento':
      case 'em andamento':
        return const Color(0xFF3B82F6);
      case 'aguardando_aprovacao_orcamento':
      case 'awaiting_quote_approval':
        return const Color(0xFFF59E0B);
      case 'aguardando_autorizacao_inicio':
      case 'awaiting_service_start':
        return const Color(0xFF0EA5E9);
      case 'veiculo_na_oficina':
      case 'vehicle_at_workshop':
        return const Color(0xFF06B6D4);
      case 'aguardando_aprovacao_finalizacao':
      case 'awaiting_finalization_approval':
        return const Color(0xFF06B6D4);
      case 'em_disputa':
      case 'in_dispute':
        return const Color(0xFFDC2626);
      case 'pendente_cliente':
        return const Color(0xFFF59E0B);
      case 'finalizado_aguardando_pagamento':
      case 'aguardando_pagamento':
      case 'awaiting_payment':
        return const Color(0xFF8B5CF6);
      case 'pago':
      case 'paid':
        return const Color(0xFF10B981);
      case 'completed':
      case 'concluido':
      case 'concluído':
        return const Color(0xFF10B981);
      case 'cancelled':
      case 'cancelado':
        return const Color(0xFFEF4444);
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
      case 'aguardando_aprovacao_orcamento':
      case 'awaiting_quote_approval':
        return 'Aguardando Aprovação do Orçamento';
      case 'aguardando_autorizacao_inicio':
      case 'awaiting_service_start':
        return 'Aguardando Autorização de Início';
      case 'veiculo_na_oficina':
      case 'vehicle_at_workshop':
        return 'Veículo na Oficina';
      case 'aguardando_aprovacao_finalizacao':
      case 'awaiting_finalization_approval':
        return 'Aguardando Aprovação da Finalização';
      case 'em_disputa':
      case 'in_dispute':
        return 'Em Disputa';
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
        return status.isEmpty ? 'Desconhecido' : status;
    }
  }

  String _formatDate(String? dateTime) {
    if (dateTime == null) return 'Data não informada';
    
    try {
      final date = DateTime.parse(dateTime);
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      return 'Data inválida';
    }
  }

  String _formatTime(String? dateTime) {
    if (dateTime == null) return 'Hora não informada';
    
    try {
      final date = DateTime.parse(dateTime);
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
                final url = upload['url'] ?? upload['signed_url'] ?? '';
                
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
                    // Abrir imagem em tela cheia
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
                          child: CircularProgressIndicator(
                            color: Color(0xFF00C977),
                          ),
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








