import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meca_app_oficina/services/api_service.dart';
import 'package:meca_app_oficina/services/appsflyer_service.dart';
import 'package:meca_app_oficina/utils/price_utils.dart';
import 'package:meca_app_oficina/utils/currency_formatter.dart';
import 'package:meca_app_oficina/widgets/beautiful_error_snackbar.dart';

class BuildQuoteScreen extends StatefulWidget {
  final String bookingId;
  final List<Map<String, dynamic>>? existingItems;
  final int? existingDiagnosticValue;
  final bool isEditMode;
  final bool isFinishMode;

  const BuildQuoteScreen({
    Key? key,
    required this.bookingId,
    this.existingItems,
    this.existingDiagnosticValue,
    this.isEditMode = false,
    this.isFinishMode = false,
  }) : super(key: key);

  @override
  State<BuildQuoteScreen> createState() => _BuildQuoteScreenState();
}

class _BuildQuoteScreenState extends State<BuildQuoteScreen> {
  final ApiService _apiService = ApiService();
  final List<QuoteItem> _items = [];
  final TextEditingController _diagnosticController = TextEditingController();
  final TextEditingController _quoteReasonController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<FocusNode> _descriptionFocusNodes = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItems != null && widget.existingItems!.isNotEmpty) {
      _items.addAll(widget.existingItems!.map((item) => QuoteItem(
        description: item['description']?.toString() ?? '',
        quantity: int.tryParse(item['quantity']?.toString() ?? '') ?? 1,
        unitPrice: (num.tryParse(item['unit_price']?.toString() ?? '') ?? 0) / 100.0,
        priority: int.tryParse(item['priority']?.toString() ?? '') ?? 3,
        originalItemId: item['id']?.toString(),
        options: (item['options'] as List<dynamic>?)?.map((opt) => QuoteItemOption(
          description: opt['description']?.toString(),
          unitPrice: (num.tryParse(opt['unit_price']?.toString() ?? '') ?? 0) / 100.0,
          isDefault: opt['is_default'] == true,
        )).toList(),
      )));
    }
    _descriptionFocusNodes.addAll(List.generate(_items.length, (_) => FocusNode()));
    if (widget.existingDiagnosticValue != null && widget.existingDiagnosticValue! > 0) {
      _diagnosticController.text = (widget.existingDiagnosticValue! / 100.0).toStringAsFixed(2).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    for (var node in _descriptionFocusNodes) {
      node.dispose();
    }
    _diagnosticController.dispose();
    _quoteReasonController.dispose();
    for (var item in _items) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.unitPriceController.dispose();
      for (var opt in item.options) {
        opt.descriptionController.dispose();
        opt.unitPriceController.dispose();
        opt.descriptionFocusNode.dispose();
      }
    }
    super.dispose();
  }

  void _addItem() {
    final newNode = FocusNode();
    _descriptionFocusNodes.add(newNode);

    FocusScope.of(context).unfocus();

    setState(() {
      _items.add(QuoteItem());
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _descriptionFocusNodes.length != _items.length) return;
      _descriptionFocusNodes.last.requestFocus();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].descriptionController.dispose();
      _items[index].quantityController.dispose();
      _items[index].unitPriceController.dispose();
      for (var opt in _items[index].options) {
        opt.descriptionController.dispose();
        opt.unitPriceController.dispose();
        opt.descriptionFocusNode.dispose();
      }
      _descriptionFocusNodes[index].dispose();
      _items.removeAt(index);
      _descriptionFocusNodes.removeAt(index);
    });
  }

  double _calculateItemsTotal() {
    return _items.fold(0.0, (sum, item) {
      final quantity = double.tryParse(item.quantityController.text) ?? 1;
      // IMPORTANTE: Usar CurrencyTextInputFormatter.parseToCents para parsear corretamente o valor formatado
      final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
      final unitPrice = unitPriceCents / 100.0;
      return sum + (quantity * unitPrice);
    });
  }

  double _calculateDiagnostic() {
    // IMPORTANTE: Usar CurrencyTextInputFormatter.parseToCents para parsear corretamente o valor formatado
    final diagnosticCents = CurrencyTextInputFormatter.parseToCents(_diagnosticController.text) ?? 0;
    return diagnosticCents / 100.0;
  }

  double _calculateTotal() {
    return _calculateItemsTotal() + _calculateDiagnostic();
  }

  Future<void> _sendQuote() async {
    if (_items.isEmpty) {
      BeautifulErrorSnackbar.show(context, 'Adicione pelo menos um item ao orçamento.');
      return;
    }

      for (var item in _items) {
        if (item.descriptionController.text.trim().isEmpty) {
          BeautifulErrorSnackbar.show(context, 'Todos os itens devem ter uma descrição.');
          return;
        }
        final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
        if (unitPriceCents <= 0) {
          BeautifulErrorSnackbar.show(context, 'Todos os itens devem ter um valor unitário maior que zero.');
          return;
        }
      }

    setState(() => _isLoading = true);

    try {
      final itemsPayload = _items.map((item) {
        final quantity = int.tryParse(item.quantityController.text) ?? 1;
        final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
        final Map<String, dynamic> payload = {
          'description': item.descriptionController.text.trim(),
          'quantity': quantity,
          'unitPrice': unitPriceCents,
          'priority': item.priority,
        };
        if (item.originalItemId != null) {
          payload['originalItemId'] = item.originalItemId;
        }
        if (item.options.isNotEmpty) {
          payload['options'] = item.options.map((opt) {
            final optPriceCents = CurrencyTextInputFormatter.parseToCents(opt.unitPriceController.text) ?? 0;
            return {
              'description': opt.descriptionController.text.trim(),
              'unit_price': optPriceCents,
              'is_default': opt.isDefault,
            };
          }).toList();
        }
        return payload;
      }).toList();

      // IMPORTANTE: Usar CurrencyTextInputFormatter para parsear o valor formatado
      final diagnosticValueCents = CurrencyTextInputFormatter.parseToCents(_diagnosticController.text);

      final quoteReason = _quoteReasonController.text.trim().isNotEmpty 
          ? _quoteReasonController.text.trim() 
          : null;

      // IMPORTANTE: Durante edição de orçamento, o motivo é OBRIGATÓRIO
      if (widget.isEditMode && (quoteReason == null || quoteReason.isEmpty)) {
        BeautifulErrorSnackbar.showWarning(context, 'É obrigatório informar o motivo da mudança do orçamento.');
        return;
      }

      final result = widget.isFinishMode
          ? await _apiService.finishService(
              widget.bookingId,
              items: itemsPayload,
              diagnosticValueCents: diagnosticValueCents,
              quoteReason: quoteReason,
            )
          : widget.isEditMode
              ? await _apiService.editQuote(
                  widget.bookingId,
                  items: itemsPayload,
                  diagnosticValueCents: diagnosticValueCents,
                  quoteReason: quoteReason,
                )
              : await _apiService.sendQuote(
                  widget.bookingId,
                  items: itemsPayload,
                  diagnosticValueCents: diagnosticValueCents,
                  quoteReason: quoteReason,
                );

      if (!mounted) return;

      if (result['success'] == true) {
        if (!widget.isEditMode) {
          final totalCents = itemsPayload.fold<int>(0, (sum, i) => sum + (((i['quantity'] as int?) ?? 0) * ((i['unitPrice'] as int?) ?? 0))) + (diagnosticValueCents ?? 0);
          AppsFlyerService.instance.logQuoteSent(widget.bookingId, totalCents / 100.0);
        }
        Navigator.of(context).pop(true);
        if (context.mounted) {
          BeautifulErrorSnackbar.showSuccess(
            context,
            widget.isEditMode
                ? 'Orçamento atualizado! Aguardando aprovação do cliente.'
                : 'Orçamento enviado! O cliente foi notificado.',
          );
        }
      } else {
        BeautifulErrorSnackbar.show(context, result['error'] ?? 'Erro ao enviar orçamento.');
      }
    } catch (e) {
      if (!mounted) return;
      BeautifulErrorSnackbar.show(context, 'Erro: ${e.toString()}');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final total = _calculateTotal();
    final itemsTotal = _calculateItemsTotal();
    final diagnosticValue = _calculateDiagnostic();

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Text(
          widget.isFinishMode 
              ? 'Orçamento Final'
              : widget.isEditMode 
                  ? 'Editar Orçamento'
                  : 'Montar Orçamento',
        ),
        backgroundColor: widget.isFinishMode ? const Color(0xFF00C977) : Colors.orange,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.all(20),
              children: [
                // Header informativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isEditMode
                          ? [
                              Colors.orange.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ]
                          : [
                              Colors.orange.withOpacity(0.1),
                              Colors.orange.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isEditMode ? Colors.orange : Colors.orange.withOpacity(0.3),
                      width: widget.isEditMode ? 2 : 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isEditMode ? Colors.orange.withOpacity(0.3) : Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          widget.isEditMode ? Icons.edit : Icons.receipt_long,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!widget.isEditMode)
                              Text(
                                'Montar Orçamento',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange,
                                ),
                              ),
                            if (!widget.isEditMode) const SizedBox(height: 4),
                            widget.isEditMode
                                ? RichText(
                                    text: TextSpan(
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange.shade800,
                                        fontWeight: FontWeight.normal,
                                      ),
                                      children: const [
                                        TextSpan(
                                          text: 'ATENÇÃO: ',
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        TextSpan(
                                          text: 'Ao alterar o orçamento, o serviço será pausado e o cliente precisará aprovar o novo valor. Se rejeitado, o orçamento anterior será restaurado.',
                                        ),
                                      ],
                                    ),
                                  )
                                : Text(
                                    widget.isFinishMode
                                        ? 'Orçamento final após conclusão do serviço'
                                        : 'Adicione os itens do serviço e o valor do diagnóstico (opcional)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),

                // Seção de Items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00C977).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.inventory_2,
                            color: Color(0xFF00C977),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Itens do Orçamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF00C977),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00C977).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.add, color: Colors.white),
                        onPressed: _addItem,
                        tooltip: 'Adicionar item',
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 16),
                
                if (_items.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.2),
                        width: 1.5,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.add_circle_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Nenhum item adicionado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Clique no botão + acima para adicionar itens ao orçamento',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    return TweenAnimationBuilder<double>(
                      key: ObjectKey(item),
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 12 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF00C977).withOpacity(0.2),
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C977).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'Item ${index + 1}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF00C977),
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                  tooltip: 'Remover item',
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: item.descriptionController,
                              focusNode: index < _descriptionFocusNodes.length ? _descriptionFocusNodes[index] : null,
                              decoration: InputDecoration(
                                labelText: 'Descrição do item',
                                hintText: 'Ex: Troca de óleo, Alinhamento, Balanceamento...',
                                prefixIcon: const Icon(Icons.description, color: Color(0xFF00C977)),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                                ),
                              ),
                              onChanged: (_) => setState(() {}),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<int>(
                                    value: item.priority,
                                    decoration: InputDecoration(
                                      labelText: 'Prioridade',
                                      prefixIcon: const Icon(Icons.flag, color: Color(0xFF00C977)),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                                      ),
                                    ),
                                    items: const [
                                      DropdownMenuItem(value: 1, child: Text('1 - Opcional')),
                                      DropdownMenuItem(value: 2, child: Text('2 - Recomendado')),
                                      DropdownMenuItem(value: 3, child: Text('3 - Importante')),
                                      DropdownMenuItem(value: 4, child: Text('4 - Muito importante')),
                                      DropdownMenuItem(value: 5, child: Text('5 - Essencial')),
                                    ],
                                    onChanged: (v) {
                                      setState(() {
                                        item.priority = v ?? 3;
                                        if (item.isRequired && item.options.isNotEmpty) {
                                          for (final o in item.options) {
                                            o.descriptionController.dispose();
                                            o.unitPriceController.dispose();
                                          }
                                          item.options.clear();
                                        }
                                      });
                                    },
                                  ),
                                ),
                                if (item.isRequired) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                                    ),
                                    child: const Text('Obrigatório', style: TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: item.quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: InputDecoration(
                                      labelText: 'Quantidade',
                                      prefixIcon: const Icon(Icons.numbers, color: Color(0xFF00C977)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                                      ),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: item.unitPriceController,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      CurrencyTextInputFormatter(),
                                    ],
                                    decoration: InputDecoration(
                                      labelText: 'Valor Unitário',
                                      prefixIcon: const Icon(Icons.attach_money, color: Color(0xFF00C977)),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: const BorderSide(color: Color(0xFF00C977), width: 2),
                                      ),
                                      hintText: 'R\$ 0,00',
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Builder(
                              builder: (context) {
                                final quantity = double.tryParse(item.quantityController.text) ?? 1;
                                // IMPORTANTE: Usar CurrencyTextInputFormatter.parseToCents para parsear corretamente o valor formatado
                                final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
                                final unitPrice = unitPriceCents / 100.0;
                                final itemTotal = quantity * unitPrice;
                                return Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF00C977).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Subtotal do item:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      Text(
                                        PriceUtils.formatPrice(itemTotal),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Color(0xFF00C977),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 12),
                            if (!item.isRequired && item.options.isNotEmpty) ...[
                              const Divider(),
                              const SizedBox(height: 8),
                              Text('Opções alternativas', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              ...List.generate(item.options.length, (optIdx) {
                                final opt = item.options[optIdx];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: isDarkMode ? const Color(0xFF222222) : Colors.grey[50],
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: opt.isDefault ? const Color(0xFF00C977) : Colors.grey.withOpacity(0.2)),
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Radio<int>(
                                            value: optIdx,
                                            groupValue: item.options.indexWhere((o) => o.isDefault),
                                            activeColor: const Color(0xFF00C977),
                                            onChanged: (v) {
                                              setState(() {
                                                for (var o in item.options) o.isDefault = false;
                                                opt.isDefault = true;
                                              });
                                            },
                                          ),
                                          const Text('Padrão', style: TextStyle(fontSize: 12)),
                                          const Spacer(),
                                          IconButton(
                                            icon: const Icon(Icons.close, size: 18, color: Colors.red),
                                            onPressed: () => setState(() {
                                              opt.descriptionController.dispose();
                                              opt.unitPriceController.dispose();
                                              opt.descriptionFocusNode.dispose();
                                              item.options.removeAt(optIdx);
                                            }),
                                          ),
                                        ],
                                      ),
                                      TextField(
                                        controller: opt.descriptionController,
                                        focusNode: opt.descriptionFocusNode,
                                        decoration: InputDecoration(
                                          labelText: 'Descrição da opção',
                                          isDense: true,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: opt.unitPriceController,
                                        keyboardType: TextInputType.number,
                                        inputFormatters: [CurrencyTextInputFormatter()],
                                        decoration: InputDecoration(
                                          labelText: 'Valor',
                                          isDense: true,
                                          hintText: 'R\$ 0,00',
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onChanged: (_) => setState(() {}),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                            if (!item.isRequired)
                              TextButton.icon(
                                onPressed: () {
                                  FocusScope.of(context).unfocus();
                                  final newOption = QuoteItemOption(isDefault: item.options.isEmpty);
                                  setState(() {
                                    item.options.add(newOption);
                                  });
                                  WidgetsBinding.instance.addPostFrameCallback((_) {
                                    if (!mounted) return;
                                    newOption.descriptionFocusNode.requestFocus();
                                  });
                                },
                                icon: const Icon(Icons.add_circle_outline, size: 18, color: Color(0xFF00C977)),
                                label: const Text('Adicionar opção', style: TextStyle(color: Color(0xFF00C977), fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                  }),

                const SizedBox(height: 24),

                // Valor do diagnóstico
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.1),
                        Colors.blue.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.search,
                              color: Colors.blue,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Valor do Diagnóstico (Opcional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Valor cobrado pela análise do veículo. Se o cliente não aprovar o orçamento, ele pagará apenas este valor.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _diagnosticController,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          CurrencyTextInputFormatter(),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Valor do Diagnóstico',
                          prefixIcon: const Icon(Icons.attach_money, color: Colors.blue),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue, width: 2),
                          ),
                          hintText: 'R\$ 0,00',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Campo de motivo do orçamento
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.isEditMode
                          ? [
                              Colors.orange.withOpacity(0.2),
                              Colors.orange.withOpacity(0.1),
                            ]
                          : [
                              Colors.purple.withOpacity(0.1),
                              Colors.purple.withOpacity(0.05),
                            ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isEditMode ? Colors.orange : Colors.purple.withOpacity(0.3),
                      width: widget.isEditMode ? 2 : 1.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: widget.isEditMode ? Colors.orange.withOpacity(0.3) : Colors.purple.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              widget.isEditMode ? Icons.warning : Icons.note_alt,
                              color: widget.isEditMode ? Colors.orange : Colors.purple,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.isEditMode
                                  ? 'Motivo do Orçamento (Obrigatório) ⚠️'
                                  : 'Motivo do Orçamento (Opcional)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: widget.isEditMode ? Colors.orange : null,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.isEditMode
                            ? '⚠️ OBRIGATÓRIO: Explique claramente por que o orçamento foi alterado. Esta informação será enviada ao cliente para que ele possa entender a mudança antes de aprovar ou rejeitar.'
                            : 'Explique o motivo deste orçamento, das peças e do preço. Esta informação será visível para o cliente.',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isEditMode ? Colors.orange.shade700 : Colors.grey[600],
                          height: 1.4,
                          fontWeight: widget.isEditMode ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _quoteReasonController,
                        maxLines: 5,
                        decoration: InputDecoration(
                          labelText: 'Motivo do orçamento${widget.isEditMode ? ' *' : ''}',
                          hintText: widget.isEditMode
                              ? 'Ex: Durante o serviço, descobrimos que além das pastilhas de freio, os discos também precisam ser trocados. Isso aumenta o valor em R\$ 200,00, mas garante maior segurança e durabilidade.'
                              : 'Ex: Necessária troca de pastilhas de freio devido ao desgaste excessivo. Utilizaremos peças originais com garantia de 6 meses. Mão de obra inclui alinhamento e balanceamento das rodas.',
                          prefixIcon: Icon(Icons.description, color: widget.isEditMode ? Colors.orange : Colors.purple),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: widget.isEditMode ? Colors.orange : Colors.purple, width: 2),
                          ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Resumo do orçamento
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00C977), Color(0xFF00B369)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00C977).withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.receipt, color: Colors.white, size: 24),
                          SizedBox(width: 12),
                          Text(
                            'Resumo do Orçamento',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSummaryRow('Total dos Itens:', PriceUtils.formatPrice(itemsTotal), Colors.white),
                      if (diagnosticValue > 0) ...[
                        const SizedBox(height: 12),
                        _buildSummaryRow('Diagnóstico:', PriceUtils.formatPrice(diagnosticValue), Colors.white70),
                      ],
                      const Divider(color: Colors.white38, height: 24),
                      _buildSummaryRow(
                        'Valor Total:',
                        PriceUtils.formatPrice(total),
                        Colors.white,
                        isTotal: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Botão de enviar
          Container(
            padding: const EdgeInsets.all(20),
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
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.isFinishMode ? const Color(0xFF00C977) : Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 4,
                    shadowColor: (widget.isFinishMode ? const Color(0xFF00C977) : Colors.orange).withOpacity(0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              widget.isFinishMode ? Icons.check_circle : Icons.send,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              widget.isFinishMode 
                                  ? 'Finalizar Serviço' 
                                  : widget.isEditMode
                                      ? 'Atualizar Orçamento'
                                      : 'Enviar Orçamento',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color textColor, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 18 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: textColor,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isTotal ? 22 : 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

class QuoteItemOption {
  final TextEditingController descriptionController;
  final TextEditingController unitPriceController;
  final FocusNode descriptionFocusNode;
  bool isDefault;

  QuoteItemOption({String? description, double? unitPrice, this.isDefault = false})
      : descriptionController = TextEditingController(text: description ?? ''),
        descriptionFocusNode = FocusNode(),
        unitPriceController = TextEditingController(
          text: unitPrice != null && unitPrice > 0
            ? 'R\$ ${unitPrice.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'R\$ 0,00'
        );
}

class QuoteItem {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;
  int priority;
  List<QuoteItemOption> options;
  final String? originalItemId;

  bool get isRequired => priority == 5;

  QuoteItem({
    String? description,
    int? quantity,
    double? unitPrice,
    this.priority = 3,
    List<QuoteItemOption>? options,
    this.originalItemId,
  })  : descriptionController = TextEditingController(text: description ?? ''),
        quantityController = TextEditingController(text: (quantity ?? 1).toString()),
        unitPriceController = TextEditingController(
          text: unitPrice != null && unitPrice > 0
            ? 'R\$ ${unitPrice.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'R\$ 0,00'
        ),
        options = options ?? [];
}
