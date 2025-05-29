import 'dart:io';

import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class RegisterProvider {
  RegisterProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<String?> onRegisterWorkshop(WorkshopModel workshop) async {
    final response = await _restClientDio.post(
      BaseUrls.workshop,
      data: workshop.toJson(),
    );
    return response.message;
  }

  Future<MegaFile> onUploadImage(File fileImage) async {
    return _restClientDio.uploadFile(
      file: fileImage,
      returnWithUrl: true,
    );
  }
}
