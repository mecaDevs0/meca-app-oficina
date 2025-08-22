import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';
import '../models/workshop_service_model.dart';

class CreateServiceProvider {
  CreateServiceProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<String?> onCreateService(ServiceModel service) async {
    final response = await _restClientDio.post(
      BaseUrls.service,
      data: service.toJson(),
    );
    return response.message;
  }

  Future<MegaFile> onUploadImage(File fileImage) async {
    return _restClientDio.uploadFile(
      file: fileImage,
      returnWithUrl: true,
    );
  }

  Future<ServiceModel> getServiceDetail(String id) async {
    final response = await _restClientDio.get('${BaseUrls.service}/$id');
    return ServiceModel.fromJson(response.data);
  }

  Future<String?> onEditService(ServiceModel editedService) async {
    final response = await _restClientDio.patch(
      '${BaseUrls.service}/${editedService.id}',
      data: editedService.toJson(),
    );
    return response.message;
  }

  Future<List<DefaultServiceModel>> getDefaultServices() async {
    final response = await _restClientDio
        .get('${BaseUrls.defaultService}?Limit=0&DataBlocked=0');
    return List<DefaultServiceModel>.from(
      response.data.map((item) => DefaultServiceModel.fromJson(item)),
    );
  }

  Future<String?> saveWorkshopServices(String workshopId, List<String> serviceIds) async {
    try {
      // 1. Primeiro buscar os serviços já cadastrados na oficina
      print('🔍 Buscando serviços já cadastrados na oficina...');
      final existingServices = await getWorkshopServices(workshopId);
      final existingServiceIds = existingServices.map((s) => s.service?.id).whereType<String>().toSet();
      
      print('✅ ${existingServices.length} serviços já cadastrados encontrados');
      print('📋 IDs dos serviços existentes: ${existingServiceIds.toList()}');

      // 2. Filtrar apenas os serviços que ainda não existem
      final newServiceIds = serviceIds.where((id) => !existingServiceIds.contains(id)).toList();
      
      if (newServiceIds.isEmpty) {
        print('✅ Todos os serviços selecionados já estão cadastrados');
        return 'Todos os serviços selecionados já estão cadastrados';
      }

      print('🆕 ${newServiceIds.length} novos serviços para cadastrar: ${newServiceIds}');

      // 3. Buscar dados dos serviços padrão
      final defaultServices = await getDefaultServices();
      print('✅ ${defaultServices.length} serviços padrão encontrados');

      // 4. Salvar apenas os novos serviços
      for (final serviceId in newServiceIds) {
        try {
          final defaultService = defaultServices.firstWhere(
            (service) => service.id == serviceId,
            orElse: () => throw Exception('Serviço padrão não encontrado: $serviceId'),
          );

          // Criar o objeto WorkshopServicesViewModel
          final workshopServiceData = {
            'service': {
              'id': serviceId,
              'name': defaultService.name,
            },
            'quickService': defaultService.quickService ?? false,
            'minTimeScheduling': defaultService.minTimeScheduling ?? 1.0,
            'description': defaultService.description ?? '',
            'estimatedTime': 1.0, // Valor padrão
            'photo': defaultService.photo ?? '',
          };

          print('🔧 Salvando novo serviço: ${defaultService.name}');
          final response = await _restClientDio.post(
            BaseUrls.service,
            data: workshopServiceData,
          );

          print('✅ Serviço ${defaultService.name} salvo com sucesso');
        } catch (e) {
          print('❌ Erro ao salvar serviço $serviceId: $e');
          return 'Erro ao salvar serviço: $e';
        }
      }

      return 'Serviços salvos com sucesso';
    } catch (e) {
      print('❌ Erro geral ao salvar serviços: $e');
      return 'Erro ao salvar serviços: $e';
    }
  }

  /// Busca os serviços já cadastrados na oficina
  Future<List<WorkshopServiceModel>> getWorkshopServices(String workshopId) async {
    try {
      final response = await _restClientDio.get(
        BaseUrls.service,
        queryParameters: {'workshopId': workshopId},
      );

      final responseData = response.data;
      List servicesList;
      
      if (responseData is Map<String, dynamic>) {
        servicesList = responseData['data'] as List;
      } else if (responseData is List) {
        servicesList = responseData;
      } else {
        print('❌ Formato de resposta inesperado para WorkshopServices');
        return [];
      }

      return servicesList
          .map<WorkshopServiceModel>(
            (service) => WorkshopServiceModel.fromJson(service as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      print('❌ Erro ao buscar serviços da oficina: $e');
      return [];
    }
  }
}
