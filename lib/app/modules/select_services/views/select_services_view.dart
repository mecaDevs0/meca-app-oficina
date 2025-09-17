import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/select_services_controller.dart';

class SelectServicesView extends StatefulWidget {
  const SelectServicesView({super.key});

  @override
  State<SelectServicesView> createState() => _SelectServicesViewState();
}

class _SelectServicesViewState
    extends MegaState<SelectServicesView, SelectServicesController> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(
        title: 'Selecionar Serviços',
      ),
      body: Obx(
        () => controller.isLoadingServices
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : Column(
                children: [
                  _buildSelectAllSection(),
                  _buildServicesList(),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildSelectAllSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.grayBorderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        children: [
          // Checkbox customizado
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: controller.selectAll ? AppColors.primaryColor : Colors.transparent,
              border: Border.all(
                color: controller.selectAll ? AppColors.primaryColor : AppColors.gray300,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(6),
            ),
            child: controller.selectAll
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 16,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Selecionar Todos',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: AppColors.fontDarkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Obx(() => Text(
                  '${controller.selectedCount} de ${controller.totalCount} serviços selecionados',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.grayMedium,
                  ),
                )),
              ],
            ),
          ),
          // Botão para selecionar/deselecionar todos
          GestureDetector(
            onTap: () => controller.toggleSelectAll(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                controller.selectAll ? 'Deselecionar' : 'Selecionar',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: controller.defaultServices.length,
        itemBuilder: (context, index) {
          final service = controller.defaultServices[index];
          return _buildServiceItem(service);
        },
      ),
    );
  }

  Widget _buildServiceItem(DefaultServiceModel service) {
    final isSelected = controller.isServiceSelected(service);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? AppColors.primaryColor : AppColors.grayBorderColor,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
            spreadRadius: 0,
          ),
        ],
      ),
      child: InkWell(
        onTap: () => controller.toggleServiceSelection(service),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              // Ícone do serviço
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? AppColors.primaryColor.withOpacity(0.1)
                      : AppColors.gray100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getServiceIcon(service.name),
                  color: isSelected ? AppColors.primaryColor : AppColors.gray500,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? AppColors.primaryColor : AppColors.fontDarkGray,
                      ),
                    ),
                    if (service.description != null && service.description!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        service.description!,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grayMedium,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (service.quickService == true) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.success.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Serviço Rápido',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.success,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        if (service.minTimeScheduling != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${service.minTimeScheduling!.toInt()}h min',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: AppColors.info,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Checkbox customizado
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primaryColor : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? AppColors.primaryColor : AppColors.gray300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getServiceIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    
    if (name.contains('óleo') || name.contains('oleo')) {
      return Icons.local_gas_station;
    } else if (name.contains('pneu') || name.contains('pneus')) {
      return Icons.tire_repair;
    } else if (name.contains('freio') || name.contains('freios')) {
      return Icons.stop_circle;
    } else if (name.contains('motor') || name.contains('engines')) {
      return Icons.precision_manufacturing;
    } else if (name.contains('ar condicionado') || name.contains('ar-condicionado')) {
      return Icons.ac_unit;
    } else if (name.contains('bateria') || name.contains('baterias')) {
      return Icons.battery_charging_full;
    } else if (name.contains('suspensão') || name.contains('suspensao')) {
      return Icons.settings_suggest;
    } else if (name.contains('direção') || name.contains('direcao')) {
      return Icons.directions_car;
    } else if (name.contains('transmissão') || name.contains('transmissao')) {
      return Icons.settings;
    } else if (name.contains('elétrica') || name.contains('eletrica') || name.contains('elétrica')) {
      return Icons.electrical_services;
    } else if (name.contains('arrefecimento') || name.contains('refrigeracao')) {
      return Icons.water_drop;
    } else if (name.contains('escapamento') || name.contains('exhaust')) {
      return Icons.air;
    } else if (name.contains('vidro') || name.contains('vidros')) {
      return Icons.window;
    } else if (name.contains('luz') || name.contains('iluminação') || name.contains('iluminacao')) {
      return Icons.lightbulb;
    } else if (name.contains('pintura') || name.contains('paint')) {
      return Icons.format_paint;
    } else if (name.contains('funilaria') || name.contains('bodywork')) {
      return Icons.build;
    } else if (name.contains('limpeza') || name.contains('clean')) {
      return Icons.cleaning_services;
    } else if (name.contains('alinhamento') || name.contains('balanceamento')) {
      return Icons.tune;
    } else if (name.contains('diagnóstico') || name.contains('diagnostico')) {
      return Icons.search;
    } else if (name.contains('manutenção') || name.contains('manutencao')) {
      return Icons.build_circle;
    } else {
      return Icons.build; // Ícone padrão para serviços
    }
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Obx(() => Text(
                    '${controller.selectedCount} serviço(s) selecionado(s)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fontDarkGray,
                    ),
                  )),
                  const SizedBox(height: 4),
                  Obx(() => Text(
                    controller.selectedCount > 0 
                        ? 'Toque em "Salvar" para adicionar os serviços'
                        : 'Selecione os serviços que você oferece',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.grayMedium,
                    ),
                  )),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              flex: 2,
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor,
                      AppColors.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryColor.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: controller.isLoading ? null : () async {
                      await controller.saveSelectedServices();
                      // Não precisa chamar Get.back() aqui pois o controller já faz isso
                    },
                    child: Center(
                      child: controller.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Salvar Seleção',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
