import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class EditProfileProvider {
  EditProfileProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<WorkshopModel> onUpdateWorkshop(WorkshopModel workshop) async {
    final response = await _restClientDio.patch(
      '${BaseUrls.workshop}/${workshop.id}',
      data: workshop.toJson(),
    );
    return WorkshopModel.fromJson(response.data);
  }

  Future<MegaFile> onUploadImage(File fileImage) async {
    return _restClientDio.uploadFile(
      file: fileImage,
      returnWithUrl: true,
    );
  }
}
