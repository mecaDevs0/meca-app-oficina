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
}
