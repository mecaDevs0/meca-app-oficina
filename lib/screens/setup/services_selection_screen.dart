import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/colors.dart';
import '../../providers/services_provider.dart';

class ServicesSelectionScreen extends StatefulWidget {
  const ServicesSelectionScreen({super.key});

  @override
  State<ServicesSelectionScreen> createState() => _ServicesSelectionScreenState();
}

class _ServicesSelectionScreenState extends State<ServicesSelectionScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServicesProvider>(context, listen: false).loadMasterServices();
    });
  }

  @override
  Widget build(BuildContext context) {
    final servicesProvider = Provider.of<ServicesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        title: const Text('Selecionar Serviços'),
      ),
      body: servicesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                      const Text(
                        'Serviços Disponíveis',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selecione os serviços que sua oficina oferece',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: servicesProvider.masterServices.length,
              itemBuilder: (context, index) {
                      final service = servicesProvider.masterServices[index];
                      final isSelected = servicesProvider.isServiceSelected(service['id']);

                return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isSelected 
                                ? AppColors.primary 
                                : Colors.grey.shade300,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                  child: CheckboxListTile(
                          value: isSelected,
                          onChanged: (value) async {
                            if (value == true) {
                              // Adicionar serviço - preço e duração são opcionais
                              final config = await _showServiceConfigDialog(context, service['title']);
                              if (mounted) {
                                if (config != null) {
                                  await servicesProvider.addService(
                                    service['id'],
                                    price: config.price,
                                    duration: config.duration,
                                  );
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(config.price != null || config.duration != null
                                            ? 'Serviço adicionado com sucesso!'
                                            : 'Serviço adicionado (sem preço/duração definidos).'),
                                        backgroundColor: Colors.green,
                                      ),
                                    );
                                  }
                                } else {
                                  // Usuário cancelou - não fazer nada
                                }
                              }
                            } else {
                              // Remover serviço
                              await servicesProvider.removeService(service['id']);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Serviço removido.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          title: Text(
                            service['title'] ?? '',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.primary : Colors.black,
                            ),
                          ),
                          subtitle: service['description'] != null
                              ? Text(service['description'])
                              : null,
                          secondary: Icon(
                            isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isSelected ? AppColors.primary : Colors.grey,
                          ),
                          activeColor: AppColors.primary,
                  ),
                );
              },
            ),
          ),
                Container(
            padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
              child: ElevatedButton(
                      onPressed: servicesProvider.myServices.isEmpty
                          ? null
                          : () {
                              if (!mounted) return;
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Serviços salvos com sucesso!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Salvar Serviços (${servicesProvider.myServices.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Future<ServiceConfig?> _showServiceConfigDialog(BuildContext context, String serviceName) async {
    final priceController = TextEditingController();
    final durationController = TextEditingController();
    
    return showDialog<ServiceConfig>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Configurar: $serviceName'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Preço (opcional)',
                  hintText: 'Ex: 150.00',
                  prefixText: 'R\$ ',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(
                  labelText: 'Duração em minutos (opcional)',
                  hintText: 'Ex: 60',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              const Text(
                'Você pode deixar os campos vazios se preferir.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final priceText = priceController.text.trim();
              final durationText = durationController.text.trim();
              
              double? price;
              if (priceText.isNotEmpty) {
                final cleaned = priceText.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
                price = double.tryParse(cleaned);
              }
              
              int? duration;
              if (durationText.isNotEmpty) {
                duration = int.tryParse(durationText);
              }
              
              Navigator.pop(ctx, ServiceConfig(price: price, duration: duration));
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }
}

class ServiceConfig {
  final double? price;
  final int? duration;

  ServiceConfig({this.price, this.duration});
}








