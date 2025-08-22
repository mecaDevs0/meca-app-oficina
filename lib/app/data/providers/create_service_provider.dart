import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

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
      // Buscar os dados do serviço padrão apenas UMA VEZ antes do loop
      print('🔍 Buscando serviços padrão...');
      final defaultServices = await getDefaultServices();
      print('✅ ${defaultServices.length} serviços padrão encontrados');
      
      // Fazer múltiplas requisições para salvar cada serviço individualmente
      for (final serviceId in serviceIds) {
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

          final response = await _restClientDio.post(
            BaseUrls.service,
            data: workshopServiceData,
          );
          
          print('✅ Serviço salvo: ${defaultService.name}');
        } catch (e) {
          print('❌ Erro ao salvar serviço $serviceId: $e');
          // Continuar com os próximos serviços mesmo se um falhar
        }
      }
      
      return 'Serviços salvos com sucesso';
    } catch (e) {
      print('❌ Erro geral ao salvar serviços: $e');
      return 'Erro ao salvar serviços';
    }
  }
}
