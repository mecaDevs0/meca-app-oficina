import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:meca_app_oficina/services/api_service.dart';
import 'package:meca_app_oficina/utils/price_utils.dart';
import 'package:meca_app_oficina/utils/currency_formatter.dart';

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
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingItems != null && widget.existingItems!.isNotEmpty) {
      _items.addAll(widget.existingItems!.map((item) => QuoteItem(
        description: item['description'] ?? '',
        quantity: item['quantity'] ?? 1,
        unitPrice: (item['unit_price'] ?? 0) / 100.0,
      )));
    }
    if (widget.existingDiagnosticValue != null && widget.existingDiagnosticValue! > 0) {
      _diagnosticController.text = (widget.existingDiagnosticValue! / 100.0).toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _diagnosticController.dispose();
    for (var item in _items) {
      item.descriptionController.dispose();
      item.quantityController.dispose();
      item.unitPriceController.dispose();
    }
    super.dispose();
  }

  void _addItem() {
    setState(() {
      _items.add(QuoteItem());
    });
  }

  void _removeItem(int index) {
    setState(() {
      _items[index].descriptionController.dispose();
      _items[index].quantityController.dispose();
      _items[index].unitPriceController.dispose();
      _items.removeAt(index);
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Adicione pelo menos um item ao orçamento'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

      for (var item in _items) {
        if (item.descriptionController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos os items devem ter uma descrição'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        // IMPORTANTE: Usar CurrencyTextInputFormatter para parsear o valor formatado
        final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
        if (unitPriceCents <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Todos os items devem ter um valor unitário maior que zero'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

    setState(() => _isLoading = true);

    try {
      final itemsPayload = _items.map((item) {
        final quantity = int.tryParse(item.quantityController.text) ?? 1;
        // IMPORTANTE: Usar CurrencyTextInputFormatter para parsear o valor formatado
        final unitPriceCents = CurrencyTextInputFormatter.parseToCents(item.unitPriceController.text) ?? 0;
        return {
          'description': item.descriptionController.text.trim(),
          'quantity': quantity,
          'unitPrice': unitPriceCents,
        };
      }).toList();

      // IMPORTANTE: Usar CurrencyTextInputFormatter para parsear o valor formatado
      final diagnosticValueCents = CurrencyTextInputFormatter.parseToCents(_diagnosticController.text);
      final diagnosticValue = diagnosticValueCents != null && diagnosticValueCents > 0 ? diagnosticValueCents : null;

      final result = widget.isFinishMode
          ? await _apiService.finishService(
              widget.bookingId,
              items: itemsPayload,
              diagnosticValueCents: diagnosticValueCents,
            )
          : widget.isEditMode
              ? await _apiService.editQuote(
                  widget.bookingId,
                  items: itemsPayload,
                  diagnosticValueCents: diagnosticValueCents,
                )
              : await _apiService.sendQuote(
                  widget.bookingId,
                  items: itemsPayload,
                  diagnosticValueCents: diagnosticValueCents,
                );

      if (!mounted) return;

      if (result['success'] == true) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Orçamento enviado com sucesso! O cliente receberá uma notificação.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
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
              padding: const EdgeInsets.all(20),
              children: [
                // Header informativo
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.orange.withOpacity(0.1),
                        Colors.orange.withOpacity(0.05),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.receipt_long,
                          color: Colors.orange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Montar Orçamento',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.isFinishMode
                                  ? 'Orçamento final após conclusão do serviço'
                                  : 'Adicione os itens do serviço e o valor do diagnóstico (opcional)',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
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
                    return Container(
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
                          ],
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

class QuoteItem {
  final TextEditingController descriptionController;
  final TextEditingController quantityController;
  final TextEditingController unitPriceController;

  QuoteItem({
    String? description,
    int? quantity,
    double? unitPrice,
  })  : descriptionController = TextEditingController(text: description ?? ''),
        quantityController = TextEditingController(text: (quantity ?? 1).toString()),
        // IMPORTANTE: Formatar valor inicial como moeda (R$ X,XX)
        unitPriceController = TextEditingController(
          text: unitPrice != null && unitPrice > 0 
            ? 'R\$ ${unitPrice.toStringAsFixed(2).replaceAll('.', ',')}'
            : 'R\$ 0,00'
        );
}
