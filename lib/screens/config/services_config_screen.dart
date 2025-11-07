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
                            final serviceId = _resolveServiceId(service);
                            final isSelected = servicesProvider.isServiceSelected(serviceId);
                            final currentData = _findMyServiceData(
                              servicesProvider.myServices,
                              serviceId,
                            );
                            final currentPrice = currentData?['price'] ??
                                currentData?['service_price'] ??
                                currentData?['workshop_price'];
                            final currentDuration = _extractDuration(currentData);
                            final masterDuration = _extractDuration(service);
                            final isProcessing = _processingServices.contains(serviceId);

                            final theme = Theme.of(context);
                            final isDarkMode = theme.brightness == Brightness.dark;
                            final cardColor = isDarkMode
                                ? const Color(0xFF1E2533)
                                : Colors.white;
                            final titleColor = isSelected
                                ? theme.colorScheme.primary
                                : (isDarkMode ? Colors.white : Colors.black87);
                            final subtitleColor = isDarkMode
                                ? Colors.white70
                                : Colors.black54;

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
                                              if (masterDuration != null && !isSelected)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 6),
                                                  child: Text(
                                                    'Duração padrão: $masterDuration min',
                                                    style: TextStyle(fontSize: 12, color: subtitleColor),
                                                  ),
                                                ),
                                              if (isSelected && currentPrice != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 8),
                                                  child: Text(
                                                    'Preço atual: R\$ ${_formatPrice(currentPrice)}',
                                                    style: TextStyle(
                                                      fontSize: 14,
                                                      fontWeight: FontWeight.w600,
                                                      color: isDarkMode ? Colors.white : Colors.black87,
                                                    ),
                                                  ),
                                                ),
                                              if (isSelected && currentDuration != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(top: 4),
                                                  child: Text(
                                                    'Duração atual: $currentDuration min',
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: isDarkMode ? Colors.white70 : Colors.black54,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Switch(
                                          value: isSelected,
                                          onChanged: isProcessing ? null : (value) => _toggleService(
                                            service,
                                            value,
                                            currentPrice: currentPrice,
                                            currentDuration: currentDuration,
                                          ),
                                          activeThumbColor: theme.colorScheme.primary,
                                          activeTrackColor: theme.colorScheme.primary.withOpacity(0.35),
                                        ),
                                      ],
                                    ),
                                    if (isSelected)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: TextButton.icon(
                                          onPressed: isProcessing
                                              ? null
                                              : () => _editServiceConfig(
                                                    service,
                                                    currentPrice: currentPrice,
                                                    currentDuration: currentDuration,
                                                  ),
                                          icon: const Icon(Icons.tune),
                                          label: const Text('Configurar preço/duração'),
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
        .map((service) => Map<String, dynamic>.from(service))
        .toList();
  }

  Future<void> _toggleService(
    Map<String, dynamic> service,
    bool value, {
    dynamic currentPrice,
    int? currentDuration,
  }) async {
    final servicesProvider = context.read<ServicesProvider>();
    final serviceId = _resolveServiceId(service);

    if (serviceId.isEmpty) return;

    setState(() {
      _processingServices.add(serviceId);
    });

    try {
      if (value) {
        final currentData = _findMyServiceData(servicesProvider.myServices, serviceId);
        final initialPrice = _parsePrice(currentPrice ?? currentData?['price'] ?? currentData?['service_price']);
        final initialDuration = currentDuration ?? _extractDuration(currentData);

        final config = await _showServiceConfigDialog(
          serviceName: service['title'] ?? service['name'] ?? 'Serviço',
          initialPrice: initialPrice,
          initialDuration: initialDuration,
        );

        if (config != null && mounted) {
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
        }
      } else {
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
      setState(() {
        _processingServices.remove(serviceId);
      });
    }
  }

  Future<void> _editServiceConfig(
    Map<String, dynamic> service, {
    dynamic currentPrice,
    int? currentDuration,
  }) async {
    final servicesProvider = context.read<ServicesProvider>();
    final serviceId = _resolveServiceId(service);

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
            ? 'Serviço atualizado na sua oficina.'
            : 'Serviço atualizado (${parts.join(' · ')}).';

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
            content: Text('Erro ao atualizar preço/duração: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _processingServices.remove(serviceId);
      });
    }
  }

  Future<_ServiceConfigResult?> _showServiceConfigDialog({
    required String serviceName,
    double? initialPrice,
    int? initialDuration,
  }) async {
    final priceController = TextEditingController(
      text: initialPrice != null ? initialPrice.toStringAsFixed(2) : '',
    );
    final durationController = TextEditingController(
      text: initialDuration != null && initialDuration > 0 ? initialDuration.toString() : '',
    );

    return showDialog<_ServiceConfigResult>(
      context: context,
      builder: (dialogContext) {
        String? priceError;
        String? durationError;

        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text('Configurar $serviceName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Preço (opcional)',
                      prefixText: 'R\$ ',
                      hintText: '150,00',
                      errorText: priceError,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Duração média (minutos) – opcional',
                      hintText: 'Ex: 60',
                      errorText: durationError,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Você pode deixar em branco para não informar preço ou duração.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    String? localPriceError;
                    String? localDurationError;

                    final priceText = priceController.text.trim().replaceAll(',', '.');
                    double? priceValue;
                    if (priceText.isNotEmpty) {
                      priceValue = double.tryParse(priceText);
                      if (priceValue == null || priceValue < 0) {
                        localPriceError = 'Informe um valor numérico válido';
                      }
                    }

                    final durationText = durationController.text.trim();
                    int? durationValue;
                    if (durationText.isNotEmpty) {
                      durationValue = int.tryParse(durationText);
                      if (durationValue == null || durationValue <= 0) {
                        localDurationError = 'Informe minutos válidos (inteiro > 0)';
                      }
                    }

                    if (localPriceError != null || localDurationError != null) {
                      setStateDialog(() {
                        priceError = localPriceError;
                        durationError = localDurationError;
                      });
                      return;
                    }

                    Navigator.of(dialogContext).pop(
                      _ServiceConfigResult(
                        price: priceValue,
                        duration: durationValue,
                      ),
                    );
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  double? _parsePrice(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    final parsed = double.tryParse(value.toString());
    return parsed;
  }

  int? _extractDuration(dynamic data) {
    if (data == null) return null;
    dynamic raw;
    if (data is Map) {
      raw = data['duration'] ??
          data['service_duration'] ??
          data['duration_minutes'] ??
          data['workshop_duration'];
    } else {
      raw = data;
    }

    if (raw == null) return null;
    if (raw is int) return raw > 0 ? raw : null;
    if (raw is num) {
      final result = raw.round();
      return result > 0 ? result : null;
    }
    final parsed = int.tryParse(raw.toString());
    if (parsed == null || parsed <= 0) return null;
    return parsed;
  }

  Map<String, dynamic>? _findMyServiceData(List<Map<String, dynamic>> services, String serviceId) {
    try {
      return services.firstWhere(
        (service) =>
            service['id'] == serviceId ||
            service['service_id'] == serviceId ||
            service['serviceId'] == serviceId,
      );
    } catch (_) {
      return null;
    }
  }

  String _resolveServiceId(Map<String, dynamic> service) {
    final id = service['id'] ?? service['service_id'] ?? service['serviceId'];
    return id?.toString() ?? '';
  }

  String _formatPrice(dynamic price) {
    if (price is num) {
      return price.toStringAsFixed(2);
    }
    final parsed = double.tryParse(price.toString());
    return parsed != null ? parsed.toStringAsFixed(2) : '0,00';
  }
}

class _ServiceConfigResult {
  const _ServiceConfigResult({this.price, this.duration});

  final double? price;
  final int? duration;
}




