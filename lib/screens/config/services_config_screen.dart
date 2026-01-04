import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/services_provider.dart';

class ServicesConfigScreen extends StatefulWidget {
  const ServicesConfigScreen({super.key});

  @override
  State<ServicesConfigScreen> createState() => _ServicesConfigScreenState();
}

class _ServicesConfigScreenState extends State<ServicesConfigScreen> {
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _processingServices = <String>{};
  bool _initialLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final servicesProvider = context.read<ServicesProvider>();
      await servicesProvider.loadMasterServices();
      await servicesProvider.loadMyServices();
      if (mounted) {
        setState(() {
          _initialLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ServicesProvider>(
      builder: (context, servicesProvider, child) {
        final allServices = servicesProvider.masterServices;
        final myServices = servicesProvider.myServices;
        final filteredServices = _filterServices(allServices);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Configurar Serviços'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Concluir',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          body: _initialLoading || servicesProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Buscar serviço por nome',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          suffixIcon: _searchController.text.isEmpty
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    setState(() {});
                                  },
                                ),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                    if (filteredServices.isEmpty)
                      Expanded(
                        child: Center(
                          child: Text(
                            _searchController.text.isEmpty
                                ? 'Nenhum serviço disponível no momento.'
                                : 'Nenhum serviço encontrado para "${_searchController.text}".',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                        ),
                      )
                    else
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: filteredServices.length,
                          itemBuilder: (context, index) {
                            final service = filteredServices[index];
                            final serviceId = _getServiceId(service);
                            final isSelected = servicesProvider.isServiceSelected(serviceId);
                            final myServiceData = servicesProvider.findMyServiceByMasterId(serviceId);
                            
                            final currentPrice = myServiceData?['price'];
                            final currentDuration = myServiceData?['duration'];
                            final isProcessing = _processingServices.contains(serviceId);

                            final theme = Theme.of(context);
                            final isDarkMode = theme.brightness == Brightness.dark;
                            final cardColor = isDarkMode ? const Color(0xFF1E2533) : Colors.white;
                            final titleColor = isSelected
                                ? theme.colorScheme.primary
                                : (isDarkMode ? Colors.white : Colors.black87);
                            final subtitleColor = isDarkMode ? Colors.white70 : Colors.black54;

                            return Card(
                              color: cardColor,
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : (isDarkMode
                                          ? Colors.white.withOpacity(0.08)
                                          : Colors.grey.shade300),
                                  width: isSelected ? 2 : 1,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                service['title'] ?? service['name'] ?? 'Serviço',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: titleColor,
                                                ),
                                              ),
                                              if (service['description'] != null &&
                                                  (service['description'] as String).isNotEmpty)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    service['description'],
                                                    style: TextStyle(fontSize: 13, color: subtitleColor),
                                                  ),
                                                ),
                                              if (isSelected && currentPrice != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    'Preço: R\$ ${_formatPrice(currentPrice)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: theme.colorScheme.primary,
                                                    ),
                                                  ),
                                                ),
                                              if (isSelected && currentDuration != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    'Duração: $currentDuration min',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: subtitleColor,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isSelected,
                                          onChanged: isProcessing
                                              ? null
                                              : (value) => _toggleService(
                                                    service,
                                                    serviceId,
                                                    value,
                                                    currentPrice: currentPrice,
                                                    currentDuration: currentDuration,
                                                  ),
                                          activeColor: theme.colorScheme.primary,
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 12),
                                        child: Align(
                                          alignment: Alignment.centerRight,
                                          child: TextButton.icon(
                                            onPressed: isProcessing
                                                ? null
                                                : () => _editServiceConfig(
                                                      service,
                                                      serviceId,
                                                      currentPrice: currentPrice,
                                                      currentDuration: currentDuration,
                                                    ),
                                            icon: const Icon(Icons.tune, size: 18),
                                            label: const Text('Configurar preço/duração'),
                                          ),
                                        ),
                                      ),
                                    if (isProcessing)
                                      const Padding(
                                        padding: EdgeInsets.only(top: 12),
                                        child: LinearProgressIndicator(minHeight: 3),
                                      ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterServices(List<Map<String, dynamic>> services) {
    if (_searchController.text.trim().isEmpty) {
      return services;
    }
    final query = _searchController.text.trim().toLowerCase();
    return services
        .where((service) {
          final title = (service['title'] ?? service['name'] ?? '').toString().toLowerCase();
          final description = (service['description'] ?? '').toString().toLowerCase();
          return title.contains(query) || description.contains(query);
        })
        .toList();
  }

  String _getServiceId(Map<String, dynamic> service) {
    // Serviços master têm 'id' como campo principal
    return service['id']?.toString() ?? '';
  }

  Future<void> _toggleService(
    Map<String, dynamic> service,
    String serviceId,
    bool value, {
    dynamic currentPrice,
    int? currentDuration,
  }) async {
    if (serviceId.isEmpty) return;

    setState(() {
      _processingServices.add(serviceId);
    });

    try {
      if (value) {
        // Adicionar serviço
        final config = await _showServiceConfigDialog(
          serviceName: service['title'] ?? service['name'] ?? 'Serviço',
          initialPrice: _parsePrice(currentPrice),
          initialDuration: currentDuration,
        );

        if (config != null && mounted) {
          final servicesProvider = context.read<ServicesProvider>();
          await servicesProvider.addService(
            serviceId,
            price: config.price,
            duration: config.duration,
          );

          if (mounted) {
            final parts = <String>[];
            if (config.price != null) {
              parts.add('preço R\$ ${_formatPrice(config.price)}');
            }
            if (config.duration != null) {
              parts.add('duração ${config.duration} min');
            }
            final content = parts.isEmpty
                ? 'Serviço adicionado à sua oficina.'
                : 'Serviço adicionado com ${parts.join(' e ')}.';

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(content),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else if (config == null && mounted) {
          // Usuário cancelou - o Switch vai voltar automaticamente porque
          // o Consumer vai reconstruir com o estado real
        }
      } else {
        // Remover serviço
        final servicesProvider = context.read<ServicesProvider>();
        await servicesProvider.removeService(serviceId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Serviço removido da sua oficina.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar serviço: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingServices.remove(serviceId);
        });
      }
    }
  }

  Future<void> _editServiceConfig(
    Map<String, dynamic> service,
    String serviceId, {
    dynamic currentPrice,
    int? currentDuration,
  }) async {
    if (serviceId.isEmpty) return;

    final config = await _showServiceConfigDialog(
      serviceName: service['title'] ?? service['name'] ?? 'Serviço',
      initialPrice: _parsePrice(currentPrice),
      initialDuration: currentDuration,
    );

    if (config == null || !mounted) return;

    setState(() {
      _processingServices.add(serviceId);
    });

    try {
      final servicesProvider = context.read<ServicesProvider>();
      await servicesProvider.addService(
        serviceId,
        price: config.price,
        duration: config.duration,
      );
      
      if (mounted) {
        final parts = <String>[];
        if (config.price != null) {
          parts.add('preço R\$ ${_formatPrice(config.price)}');
        }
        if (config.duration != null) {
          parts.add('duração ${config.duration} min');
        }
        final content = parts.isEmpty
            ? 'Configuração atualizada.'
            : 'Configuração atualizada: ${parts.join(' e ')}.';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(content),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao atualizar configuração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _processingServices.remove(serviceId);
        });
      }
    }
  }

  Future<ServiceConfig?> _showServiceConfigDialog({
    required String serviceName,
    double? initialPrice,
    int? initialDuration,
  }) async {
    final priceController = TextEditingController(
      text: initialPrice != null ? _formatPrice(initialPrice) : '',
    );
    final durationController = TextEditingController(
      text: initialDuration != null ? initialDuration.toString() : '',
    );

    return showDialog<ServiceConfig>(
      context: context,
      builder: (context) => AlertDialog(
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              final price = _parsePrice(priceController.text);
              final duration = durationController.text.trim().isEmpty
                  ? null
                  : int.tryParse(durationController.text.trim());
              Navigator.pop(
                context,
                ServiceConfig(price: price, duration: duration),
              );
            },
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      final cleaned = value.replaceAll(RegExp(r'[^\d,.]'), '').replaceAll(',', '.');
      return double.tryParse(cleaned);
    }
    return null;
  }

  String _formatPrice(dynamic price) {
    if (price == null) return '0.00';
    final value = _parsePrice(price) ?? 0.0;
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}

class ServiceConfig {
  final double? price;
  final int? duration;

  ServiceConfig({this.price, this.duration});
}
