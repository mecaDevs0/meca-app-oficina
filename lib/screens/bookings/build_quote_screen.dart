import 'package:flutter/material.dart';
import 'package:meca_app_oficina/services/api_service.dart';
import 'package:meca_app_oficina/utils/price_utils.dart';

class BuildQuoteScreen extends StatefulWidget {
  final String bookingId;
  final List<Map<String, dynamic>>? existingItems;
  final int? existingDiagnosticValue;
  final bool isEditMode; // Se true, usa editQuote ao invés de sendQuote
  final bool isFinishMode; // Se true, usa finishService ao invés de sendQuote

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
    // Carregar items existentes se houver
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

  double _calculateTotal() {
    double itemsTotal = _items.fold(0.0, (sum, item) {
      final quantity = double.tryParse(item.quantityController.text) ?? 1;
      final unitPrice = double.tryParse(item.unitPriceController.text.replaceAll(',', '.')) ?? 0;
      return sum + (quantity * unitPrice);
    });
    
    final diagnosticValue = double.tryParse(_diagnosticController.text.replaceAll(',', '.')) ?? 0;
    return itemsTotal + diagnosticValue;
  }

  Future<void> _sendQuote() async {
    // Validar items
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
      final unitPrice = double.tryParse(item.unitPriceController.text.replaceAll(',', '.')) ?? 0;
      if (unitPrice <= 0) {
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
        final unitPrice = double.tryParse(item.unitPriceController.text.replaceAll(',', '.')) ?? 0;
        return {
          'description': item.descriptionController.text.trim(),
          'quantity': quantity,
          'unitPrice': (unitPrice * 100).round(), // Converter para centavos
        };
      }).toList();

      final diagnosticValue = double.tryParse(_diagnosticController.text.replaceAll(',', '.')) ?? 0;
      final diagnosticValueCents = diagnosticValue > 0 ? (diagnosticValue * 100).round() : null;

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
        Navigator.of(context).pop(true); // Retornar true indica sucesso
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _calculateTotal();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isFinishMode 
              ? 'Finalizar Serviço - Orçamento Final'
              : widget.isEditMode 
                  ? 'Editar Orçamento'
                  : 'Montar Orçamento'
        ),
        backgroundColor: widget.isFinishMode ? const Color(0xFF00C977) : Colors.orange,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Items do orçamento
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Items do Orçamento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.orange),
                      onPressed: _addItem,
                      tooltip: 'Adicionar item',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(32.0),
                    child: Center(
                      child: Text(
                        'Nenhum item adicionado.\nClique no botão + para adicionar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  ...List.generate(_items.length, (index) {
                    final item = _items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Item ${index + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _removeItem(index),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: item.descriptionController,
                              decoration: const InputDecoration(
                                labelText: 'Descrição do item',
                                border: OutlineInputBorder(),
                                hintText: 'Ex: Troca de óleo, Alinhamento...',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: item.quantityController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Quantidade',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: item.unitPriceController,
                                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Valor Unitário (R\$)',
                                      prefixText: 'R\$ ',
                                      border: OutlineInputBorder(),
                                    ),
                                    onChanged: (_) => setState(() {}),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final quantity = double.tryParse(item.quantityController.text) ?? 1;
                                final unitPrice = double.tryParse(item.unitPriceController.text.replaceAll(',', '.')) ?? 0;
                                final itemTotal = quantity * unitPrice;
                                return Text(
                                  'Total: ${PriceUtils.formatPrice(itemTotal)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange,
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

                // Valor do diagnóstico (opcional)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Valor do Diagnóstico (Opcional)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Valor cobrado pela análise do veículo, caso o cliente não aprove o orçamento.',
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _diagnosticController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Valor do Diagnóstico (R\$)',
                            prefixText: 'R\$ ',
                            border: OutlineInputBorder(),
                            hintText: '0,00',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Resumo
                Card(
                  color: Colors.green.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resumo do Orçamento',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total dos Items:'),
                            Text(
                              PriceUtils.formatPrice(_calculateTotal() - (double.tryParse(_diagnosticController.text.replaceAll(',', '.')) ?? 0)),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        if ((double.tryParse(_diagnosticController.text.replaceAll(',', '.')) ?? 0) > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Diagnóstico:'),
                              Text(
                                PriceUtils.formatPrice(double.tryParse(_diagnosticController.text.replaceAll(',', '.')) ?? 0),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ],
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Valor Total:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              PriceUtils.formatPrice(total),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Botão de enviar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _sendQuote,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          widget.isFinishMode ? 'Finalizar Serviço' : 'Enviar Orçamento',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ],
      ),
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
        unitPriceController = TextEditingController(text: unitPrice?.toStringAsFixed(2) ?? '0,00');
}

