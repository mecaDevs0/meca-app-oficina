import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../services/api_service.dart';
import '../../services/theme_service.dart';

const _kGreen = Color(0xFF00C977);

class PreCompraDetailOfinaScreen extends StatefulWidget {
  final String preCompraId;
  const PreCompraDetailOfinaScreen({Key? key, required this.preCompraId}) : super(key: key);

  @override
  State<PreCompraDetailOfinaScreen> createState() => _PreCompraDetailOfinaScreenState();
}

class _PreCompraDetailOfinaScreenState extends State<PreCompraDetailOfinaScreen> {
  final ApiService _api = ApiService();
  Map<String, dynamic>? _item;
  bool _loading = true;
  String _error = '';

  // Ações de status
  bool _confirming = false;
  bool _starting = false;
  bool _canceling = false;
  bool _submittingLaudo = false;
  bool _uploadingPdf = false;
  late bool _isDark;

  // Formulário de laudo
  final Map<String, Map<String, dynamic>> _laudoForm = {
    'motor': {'nota': 0, 'observacao': ''},
    'transmissao': {'nota': 0, 'observacao': ''},
    'suspensao': {'nota': 0, 'observacao': ''},
    'freios': {'nota': 0, 'observacao': ''},
    'carroceria': {'nota': 0, 'observacao': ''},
    'interior': {'nota': 0, 'observacao': ''},
    'eletrica': {'nota': 0, 'observacao': ''},
    'pneus': {'nota': 0, 'observacao': ''},
    'ar_condicionado': {'nota': 0, 'observacao': ''},
    'revisao_geral': {'nota': 0, 'observacao': ''},
  };

  static const _categoriaLabels = {
    'motor': 'Motor',
    'transmissao': 'Transmissão',
    'suspensao': 'Suspensão',
    'freios': 'Freios',
    'carroceria': 'Carroceria',
    'interior': 'Interior',
    'eletrica': 'Elétrica',
    'pneus': 'Pneus',
    'ar_condicionado': 'Ar Condicionado',
    'revisao_geral': 'Revisão Geral',
  };

  String _resultado = 'aprovado';
  final _observacoesCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _observacoesCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  Future<void> _load({bool skipCache = false}) async {
    setState(() { _loading = true; _error = ''; });
    try {
      final result = await _api.get('/pre-compra/${widget.preCompraId}', skipCache: skipCache);
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        // Pré-popular laudo se já existir
        final existingLaudo = data['laudo'];
        if (existingLaudo is Map) {
          for (final key in _laudoForm.keys) {
            if (existingLaudo[key] is Map) {
              _laudoForm[key]!['nota'] = int.tryParse(existingLaudo[key]['nota']?.toString() ?? '0') ?? 0;
              _laudoForm[key]!['observacao'] = existingLaudo[key]['observacao']?.toString() ?? '';
            }
          }
        }
        if (data['resultado'] != null) _resultado = data['resultado'];
        if (data['observacoes'] != null) _observacoesCtrl.text = data['observacoes'];
        if (data['price'] != null) _priceCtrl.text = data['price'].toString();

        setState(() { _item = data; _loading = false; });
      } else {
        setState(() { _error = result['error'] ?? 'Erro'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Erro de conexão.'; _loading = false; });
    }
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final r = await _api.put('/pre-compra/${widget.preCompraId}/confirm', {});
      if (r['success'] == true) {
        if (mounted) setState(() { if (_item != null) _item!['status'] = 'confirmado'; });
        _showSnack('Confirmado!');
      } else {
        _showSnack(r['error'] ?? 'Erro', isError: true);
      }
    } catch (_) { _showSnack('Erro', isError: true); }
    finally { if (mounted) setState(() => _confirming = false); }
  }

  Future<void> _start() async {
    setState(() => _starting = true);
    try {
      final r = await _api.put('/pre-compra/${widget.preCompraId}/start', {});
      if (r['success'] == true) {
        if (mounted) setState(() { if (_item != null) _item!['status'] = 'em_andamento'; });
        _showSnack('Inspeção iniciada!');
      } else {
        _showSnack(r['error'] ?? 'Erro', isError: true);
      }
    } catch (_) { _showSnack('Erro', isError: true); }
    finally { if (mounted) setState(() => _starting = false); }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Pré-Compra'),
        content: const Text('Confirma o cancelamento?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Não')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Cancelar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    setState(() => _canceling = true);
    try {
      final r = await _api.put('/pre-compra/${widget.preCompraId}/cancel', {});
      if (r['success'] == true) {
        if (mounted) setState(() { if (_item != null) _item!['status'] = 'cancelado'; });
        _showSnack('Cancelado');
      } else {
        _showSnack(r['error'] ?? 'Erro', isError: true);
      }
    } catch (_) { _showSnack('Erro', isError: true); }
    finally { if (mounted) setState(() => _canceling = false); }
  }

  Future<void> _submitLaudo() async {
    // Validar que todas as categorias têm nota > 0
    final categoriasSemNota = _laudoForm.entries.where((e) => (e.value['nota'] as int) == 0).map((e) => _categoriaLabels[e.key]).toList();
    if (categoriasSemNota.isNotEmpty) {
      _showSnack('Avalie todas as categorias antes de enviar o laudo', isError: true);
      return;
    }

    setState(() => _submittingLaudo = true);
    try {
      // Montar laudo com observações dos controllers
      final laudoData = Map<String, dynamic>.fromEntries(
        _laudoForm.entries.map((e) => MapEntry(e.key, {
          'nota': e.value['nota'],
          'observacao': e.value['observacao'],
        })),
      );

      final body = {
        'laudo': laudoData,
        'resultado': _resultado,
        'observacoes': _observacoesCtrl.text.trim().isNotEmpty ? _observacoesCtrl.text.trim() : null,
        'price': _priceCtrl.text.trim().isNotEmpty ? double.tryParse(_priceCtrl.text.trim()) : null,
      };

      final r = await _api.put('/pre-compra/${widget.preCompraId}/submit-laudo', body);
      if (r['success'] == true) {
        _showSnack('Laudo enviado com sucesso!');
        _load(skipCache: true);
      } else {
        _showSnack(r['error'] ?? 'Erro ao enviar laudo', isError: true);
      }
    } catch (_) {
      _showSnack('Erro de conexão', isError: true);
    } finally {
      if (mounted) setState(() => _submittingLaudo = false);
    }
  }

  Future<void> _uploadPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      allowMultiple: false,
    );

    if (result == null || result.files.isEmpty) return;

    final file = result.files.first;
    if (file.path == null) {
      _showSnack('Não foi possível acessar o arquivo', isError: true);
      return;
    }

    setState(() => _uploadingPdf = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';

      final dio = Dio(BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 120),
        headers: {'Authorization': 'Bearer $token'},
      ));

      final formData = FormData.fromMap({
        'pdf': await MultipartFile.fromFile(
          file.path!,
          filename: 'laudo_pre_compra_${widget.preCompraId}.pdf',
        ),
      });

      final response = await dio.post('/pre-compra/${widget.preCompraId}/upload-pdf', data: formData);

      final data = response.data;
      if (data is Map && data['success'] == true) {
        if (mounted) setState(() { if (_item != null) _item!['laudo_pdf_key'] = 'uploaded'; });
        _showSnack('PDF enviado com sucesso! O cliente poderá baixar após pagamento.');
      } else {
        final errMsg = data is Map ? (data['error'] ?? data['message'] ?? 'Erro ao enviar PDF') : 'Erro ao enviar PDF';
        _showSnack(errMsg.toString(), isError: true);
      }
    } catch (e) {
      String msg = 'Erro ao enviar PDF.';
      if (e is DioException && e.response != null) {
        final rawData = e.response!.data;
        String errDetail = '';
        if (rawData is Map) {
          errDetail = rawData['error']?.toString() ?? rawData['message']?.toString() ?? '';
        }
        msg = 'Erro ${e.response!.statusCode}: ${errDetail.isNotEmpty ? errDetail : (e.message ?? 'Falha no upload')}';
      } else if (e is DioException) {
        msg = 'Sem conexão com o servidor.';
      }
      _showSnack(msg, isError: true);
    } finally {
      if (mounted) setState(() => _uploadingPdf = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red[700] : _kGreen,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    _isDark = Provider.of<ThemeService>(context).isDarkMode;
    return Scaffold(
      backgroundColor: ThemeService.getBackgroundColor(_isDark),
      appBar: AppBar(
        title: const Text('Pré-Compra', style: TextStyle(color: _kGreen, fontWeight: FontWeight.bold)),
        backgroundColor: ThemeService.getCardColor(_isDark),
        elevation: 0,
        iconTheme: const IconThemeData(color: _kGreen),
        actions: [
          IconButton(icon: const Icon(Icons.refresh, color: _kGreen), onPressed: () => _load(skipCache: true)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _kGreen))
          : _error.isNotEmpty
              ? _buildError()
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final item = _item!;
    final status = item['status']?.toString() ?? 'pendente';
    final paymentStatus = item['payment_status']?.toString() ?? 'pendente';
    final isPago = paymentStatus == 'pago';
    final customerName = '${item['customer_name'] ?? ''} ${item['customer_last_name'] ?? ''}'.trim();
    final customerPhone = item['customer_phone']?.toString() ?? '';
    final brand = item['vehicle_brand']?.toString() ?? '';
    final model = item['vehicle_model']?.toString() ?? '';
    final year = item['vehicle_year']?.toString() ?? '';
    final plate = item['vehicle_plate']?.toString() ?? '';
    final color = item['vehicle_color']?.toString() ?? '';
    final km = item['vehicle_km']?.toString() ?? '';
    final notes = item['notes']?.toString() ?? '';
    final dateStr = item['appointment_date']?.toString();
    final hasPdf = item['laudo_pdf_key'] != null;
    final isAguardandoPagamento = status == 'aguardando_pagamento';
    final isConcluido = status == 'concluido'; // concluido agora sempre significa pago
    final price = item['price'];

    String formattedDate = '';
    if (dateStr != null) {
      try { formattedDate = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(dateStr).toLocal()); } catch (_) {}
    }

    return RefreshIndicator(
      color: _kGreen,
      onRefresh: () => _load(skipCache: true),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Status
          _statusBanner(status),
          const SizedBox(height: 16),

          // Card de aguardando pagamento (laudo enviado, cliente ainda não pagou)
          if (isAguardandoPagamento) ...[
            _buildAguardandoPagamentoCard(price),
            const SizedBox(height: 12),
          ],

          // Card de pagamento recebido (concluido = sempre pago)
          if (isConcluido) ...[
            _buildPagamentoRecebidoCard(price, item['paid_at']?.toString()),
            const SizedBox(height: 12),
          ],

          // Cliente
          _section('Cliente', [
            _row(Icons.person, 'Nome', customerName.isNotEmpty ? customerName : 'N/A'),
            if (customerPhone.isNotEmpty) _row(Icons.phone, 'Telefone', customerPhone),
            if (formattedDate.isNotEmpty) _row(Icons.calendar_today, 'Agendado para', formattedDate),
            if (notes.isNotEmpty) _row(Icons.notes, 'Observações do cliente', notes),
          ]),
          const SizedBox(height: 12),

          // Veículo
          _section('Veículo a Inspecionar', [
            _row(Icons.directions_car, 'Veículo', '$brand $model${year.isNotEmpty ? ' ($year)' : ''}'),
            if (plate.isNotEmpty) _row(Icons.badge, 'Placa', plate),
            if (color.isNotEmpty) _row(Icons.color_lens, 'Cor', color),
            if (km.isNotEmpty) _row(Icons.speed, 'Quilometragem', '$km km'),
          ]),
          const SizedBox(height: 12),

          // Ações principais
          if (status == 'pendente') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canceling ? null : _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.08),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _canceling
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                        : const Icon(Icons.cancel_rounded, size: 20),
                    label: const Text('Recusar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _confirming ? null : _confirm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _confirming
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded, size: 20),
                    label: const Text('Confirmar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          if (status == 'confirmado') ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _starting ? null : _start,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _starting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.build_rounded, size: 20),
                    label: const Text('Iniciar Inspeção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _canceling ? null : _cancel,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withOpacity(0.08),
                      foregroundColor: Colors.red,
                      elevation: 0,
                      side: const BorderSide(color: Colors.red, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    icon: _canceling
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.red, strokeWidth: 2))
                        : const Icon(Icons.cancel_rounded, size: 20),
                    label: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // Formulário de Laudo (em_andamento)
          if (status == 'em_andamento') ...[
            _buildLaudoForm(),
            const SizedBox(height: 12),
          ],

          // Upload de PDF (em_andamento, aguardando_pagamento ou concluido)
          if (status == 'em_andamento' || isAguardandoPagamento || isConcluido) ...[
            _buildPdfSection(hasPdf),
            const SizedBox(height: 12),
          ],

          if ((isAguardandoPagamento || isConcluido) && item['resultado'] != null) ...[
            _section('Resultado Enviado', [
              _buildResultadoBadge(item['resultado'].toString()),
              if (item['observacoes'] != null) ...[
                const SizedBox(height: 8),
                Text(item['observacoes'].toString(), style: TextStyle(color: ThemeService.getTextColor(_isDark), fontSize: 14)),
              ],
            ]),
            const SizedBox(height: 12),
          ],

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildAguardandoPagamentoCard(dynamic price) {
    final priceFormatted = price != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.tryParse(price.toString()) ?? 0)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(_isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.amber.withOpacity(0.6), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.amber.withOpacity(_isDark ? 0.08 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.12),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.hourglass_top_rounded, color: Colors.amber, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Aguardando Pagamento',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: ThemeService.getTextColor(_isDark),
                        ),
                      ),
                      Text(
                        'Laudo enviado ao cliente',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.amber[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Checklist do que já foi feito
                _statusStep(icon: Icons.check_circle, color: _kGreen, text: 'Laudo de inspeção enviado'),
                const SizedBox(height: 8),
                _statusStep(icon: Icons.notifications_active, color: _kGreen, text: 'Cliente notificado por push'),
                const SizedBox(height: 8),
                _statusStep(icon: Icons.hourglass_top_rounded, color: Colors.amber, text: 'Aguardando o cliente revisar e pagar', pending: true),

                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 12),

                // Valor e info
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: Colors.amber, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Quando o cliente realizar o pagamento, você receberá uma notificação e o repasse será feito automaticamente.',
                        style: TextStyle(
                          fontSize: 13,
                          color: ThemeService.getSecondaryTextColor(_isDark),
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),

                if (priceFormatted != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kGreen.withOpacity(0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Valor a receber',
                          style: TextStyle(
                            fontSize: 13,
                            color: ThemeService.getSecondaryTextColor(_isDark),
                          ),
                        ),
                        Text(
                          priceFormatted,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                            color: _kGreen,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                // Botão de atualizar
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _load(skipCache: true),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.amber[700],
                      side: BorderSide(color: Colors.amber.withOpacity(0.7), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text(
                      'Verificar se o cliente pagou',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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

  Widget _buildPagamentoRecebidoCard(dynamic price, String? paidAt) {
    final priceFormatted = price != null
        ? NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(double.tryParse(price.toString()) ?? 0)
        : null;

    String paidAtFormatted = '';
    if (paidAt != null) {
      try { paidAtFormatted = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(paidAt).toLocal()); } catch (_) {}
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(_isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kGreen.withOpacity(0.5), width: 2),
        boxShadow: [
          BoxShadow(
            color: _kGreen.withOpacity(_isDark ? 0.08 : 0.1),
            blurRadius: 12,
            offset: const Offset(0, 3),
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
                  color: _kGreen.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.payments_rounded, color: _kGreen, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Pagamento Confirmado!',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _kGreen,
                      ),
                    ),
                    Text(
                      'O repasse foi enviado pela Asaas Gestão Financeira S.A.',
                      style: TextStyle(
                        fontSize: 12,
                        color: ThemeService.getSecondaryTextColor(_isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (priceFormatted != null || paidAtFormatted.isNotEmpty) ...[
            const SizedBox(height: 14),
            const Divider(),
            const SizedBox(height: 10),
            if (priceFormatted != null)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Valor pago', style: TextStyle(color: ThemeService.getSecondaryTextColor(_isDark), fontSize: 13)),
                  Text(priceFormatted, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: _kGreen)),
                ],
              ),
            if (paidAtFormatted.isNotEmpty) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Data do pagamento', style: TextStyle(color: ThemeService.getSecondaryTextColor(_isDark), fontSize: 13)),
                  Text(paidAtFormatted, style: TextStyle(fontSize: 13, color: ThemeService.getTextColor(_isDark), fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _statusStep({required IconData icon, required Color color, required String text, bool pending = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: pending ? Colors.amber[700] : ThemeService.getTextColor(_isDark),
              fontWeight: pending ? FontWeight.w600 : FontWeight.normal,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLaudoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(_isDark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Preencher Laudo de Inspeção', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: ThemeService.getTextColor(_isDark))),
          const SizedBox(height: 4),
          Text('Avalie cada categoria de 1 (péssimo) a 5 (excelente)', style: TextStyle(color: ThemeService.getSecondaryTextColor(_isDark), fontSize: 13)),
          const SizedBox(height: 16),

          // Categorias
          ..._categoriaLabels.entries.map((entry) => _buildCategoriaField(entry.key, entry.value)),

          const Divider(height: 24),

          // Resultado final
          Text('Resultado', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: ThemeService.getTextColor(_isDark))),
          const SizedBox(height: 8),
          DropdownButtonHideUnderline(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButton<String>(
                value: _resultado,
                isExpanded: true,
                onChanged: (v) => setState(() => _resultado = v!),
                items: const [
                  DropdownMenuItem(value: 'aprovado', child: Text('Aprovado', style: TextStyle(color: _kGreen, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'aprovado_com_ressalvas', child: Text('Aprovado com Ressalvas', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.w600))),
                  DropdownMenuItem(value: 'reprovado', child: Text('Reprovado', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600))),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Preço
          TextFormField(
            controller: _priceCtrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Valor cobrado pela inspeção (R\$)',
              prefixText: 'R\$ ',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreen, width: 2)),
            ),
          ),
          const SizedBox(height: 16),

          // Observações gerais
          TextFormField(
            controller: _observacoesCtrl,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: 'Observações gerais',
              hintText: 'Descreva o estado geral do veículo...',
              labelStyle: const TextStyle(color: Colors.grey),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: Colors.grey[300]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _kGreen, width: 2)),
            ),
          ),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _submittingLaudo ? null : _submitLaudo,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kGreen, foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: _submittingLaudo
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send),
              label: const Text('Enviar Laudo', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriaField(String key, String label) {
    final nota = _laudoForm[key]!['nota'] as int;
    final obsCtrl = TextEditingController(text: _laudoForm[key]!['observacao'] as String);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: ThemeService.getTextColor(_isDark)))),
              // Estrelas clicáveis
              Row(
                children: List.generate(5, (i) {
                  final starIndex = i + 1;
                  Color starColor;
                  if (nota == 0) starColor = Colors.grey;
                  else if (nota >= 4) starColor = _kGreen;
                  else if (nota == 3) starColor = Colors.orange;
                  else starColor = Colors.red;

                  return GestureDetector(
                    onTap: () => setState(() => _laudoForm[key]!['nota'] = starIndex),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        starIndex <= nota ? Icons.star : Icons.star_border,
                        size: 28,
                        color: starIndex <= nota ? starColor : Colors.grey[300],
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          const SizedBox(height: 6),
          TextFormField(
            controller: obsCtrl,
            onChanged: (v) => _laudoForm[key]!['observacao'] = v,
            style: const TextStyle(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Observação sobre $label (opcional)',
              hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey[200]!)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: _kGreen)),
            ),
          ),
          const Divider(height: 20),
        ],
      ),
    );
  }

  Widget _buildPdfSection(bool hasPdf) {
    final accentColor = hasPdf ? _kGreen : Colors.orange;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(_isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withOpacity(0.5), width: 1.5),
        boxShadow: _isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.picture_as_pdf, color: accentColor, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hasPdf ? 'PDF do Laudo — Enviado ✓' : 'Enviar PDF do Laudo',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: hasPdf ? _kGreen : ThemeService.getTextColor(_isDark),
                      ),
                    ),
                    if (!hasPdf)
                      Text(
                        'Siga os passos abaixo para enviar o laudo em PDF',
                        style: TextStyle(
                          fontSize: 12,
                          color: ThemeService.getSecondaryTextColor(_isDark),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasPdf) ...[
            _pdfStep('1', 'Conclua a inspeção preenchendo o laudo acima'),
            _pdfStep('2', 'Gere o PDF do laudo (pode usar Word, Google Docs, etc.)'),
            _pdfStep('3', 'Toque em "Anexar e Enviar PDF" e selecione o arquivo'),
            _pdfStep('4', 'O cliente poderá baixar o PDF após confirmar o pagamento'),
          ] else ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _kGreen.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: _kGreen, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'PDF enviado com sucesso. O cliente pode baixar após efetuar o pagamento. Toque em "Substituir" para enviar uma versão corrigida.',
                      style: TextStyle(
                        color: ThemeService.getTextColor(_isDark),
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _uploadingPdf ? null : _uploadPdf,
              style: ElevatedButton.styleFrom(
                backgroundColor: hasPdf ? Colors.grey.withOpacity(_isDark ? 0.25 : 0.15) : _kGreen,
                foregroundColor: hasPdf
                    ? ThemeService.getTextColor(_isDark)
                    : Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: _uploadingPdf
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: hasPdf ? ThemeService.getTextColor(_isDark) : Colors.white,
                      ),
                    )
                  : Icon(hasPdf ? Icons.swap_horiz : Icons.attach_file),
              label: Text(
                _uploadingPdf
                    ? 'Enviando...'
                    : (hasPdf ? 'Substituir PDF' : 'Anexar e Enviar PDF'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pdfStep(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22, height: 22,
            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle),
            child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: ThemeService.getTextColor(_isDark),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultadoBadge(String resultado) {
    Color color;
    String label;
    IconData icon;
    switch (resultado) {
      case 'aprovado': color = _kGreen; label = 'APROVADO'; icon = Icons.thumb_up; break;
      case 'reprovado': color = Colors.red; label = 'REPROVADO'; icon = Icons.thumb_down; break;
      default: color = Colors.orange; label = 'APROVADO COM RESSALVAS'; icon = Icons.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.4))),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _statusBanner(String status) {
    Color color;
    IconData icon;
    String label;
    String? subtitle;
    switch (status) {
      case 'confirmado':
        color = Colors.blue; icon = Icons.check_circle_outline;
        label = 'Confirmado'; subtitle = 'Aguardando início da inspeção';
        break;
      case 'em_andamento':
        color = Colors.orange; icon = Icons.build;
        label = 'Em Andamento'; subtitle = 'Preencha o laudo e envie ao cliente';
        break;
      case 'aguardando_pagamento':
        color = Colors.amber.shade700; icon = Icons.hourglass_top_rounded;
        label = 'Laudo Enviado'; subtitle = 'Aguardando pagamento do cliente';
        break;
      case 'concluido':
        color = _kGreen; icon = Icons.verified;
        label = 'Concluído e Pago'; subtitle = 'Pagamento confirmado pelo cliente';
        break;
      case 'cancelado':
        color = Colors.red; icon = Icons.cancel;
        label = 'Cancelado'; subtitle = null;
        break;
      default:
        color = Colors.grey; icon = Icons.hourglass_empty;
        label = 'Aguardando Confirmação'; subtitle = 'Revise os dados e confirme';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 26),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 14)),
              if (subtitle != null)
                Text(subtitle, style: TextStyle(color: color.withOpacity(0.8), fontSize: 12, height: 1.3)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThemeService.getCardColor(_isDark),
        borderRadius: BorderRadius.circular(14),
        boxShadow: _isDark ? [] : [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: _kGreen)),
        const SizedBox(height: 10),
        ...children,
      ]),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: _kGreen),
        const SizedBox(width: 8),
        SizedBox(width: 120, child: Text(label, style: TextStyle(color: ThemeService.getSecondaryTextColor(_isDark), fontSize: 13))),
        Expanded(child: Text(value, style: TextStyle(color: ThemeService.getTextColor(_isDark), fontSize: 13, fontWeight: FontWeight.w500))),
      ]),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
        const SizedBox(height: 12),
        Text(_error, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: () => _load(skipCache: true),
          style: ElevatedButton.styleFrom(backgroundColor: _kGreen, foregroundColor: Colors.white),
          child: const Text('Tentar novamente'),
        ),
      ]),
    );
  }
}
