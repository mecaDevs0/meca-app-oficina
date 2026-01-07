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
  bool _hasShownInfoDialog = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ServicesProvider>(context, listen: false).loadMasterServices();
      // Mostrar popup explicativo na primeira vez
      _showInfoDialog();
    });
  }

  Future<void> _showInfoDialog() async {
    if (_hasShownInfoDialog) return;
    _hasShownInfoDialog = true;
    
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Configuração de Serviços',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ao selecionar um serviço, você pode configurar:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              _buildInfoItem(Icons.attach_money, 'Preço', 'Valor que será cobrado pelo serviço (opcional)'),
              const SizedBox(height: 12),
              _buildInfoItem(Icons.access_time, 'Duração', 'Tempo estimado em minutos (opcional)'),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Você pode deixar os campos vazios e configurar depois nas configurações.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Entendi',
              style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
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
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.settings, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Configurar Serviço',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                serviceName,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 24),
              
              // Campo de Preço
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: priceController,
                  decoration: InputDecoration(
                    labelText: 'Preço (opcional)',
                    hintText: 'Ex: 150,00',
                    prefixIcon: Icon(Icons.attach_money, color: AppColors.primary),
                    prefixText: 'R\$ ',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              // Campo de Duração
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: TextField(
                  controller: durationController,
                  decoration: InputDecoration(
                    labelText: 'Duração em minutos (opcional)',
                    hintText: 'Ex: 60',
                    prefixIcon: Icon(Icons.access_time, color: AppColors.primary),
                    suffixText: 'min',
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    labelStyle: TextStyle(color: Colors.grey.shade600),
                  ),
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 16),
                ),
              ),
              const SizedBox(height: 16),
              
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Você pode deixar os campos vazios e configurar depois.',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // Botões
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ),
                  const SizedBox(width: 12),
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirmar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ServiceConfig {
  final double? price;
  final int? duration;

  ServiceConfig({this.price, this.duration});
}








