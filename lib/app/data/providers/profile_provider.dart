import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class ProfileProvider {
  ProfileProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<WorkshopModel> onGetProfileInfo() async {
    final response = await _restClientDio.get(BaseUrls.profile);
    return WorkshopModel.fromJson(response.data);
  }

  Future<MegaResponse> onRemoveAccount(String id) async {
    final response = await _restClientDio.delete('${BaseUrls.workshop}/$id');
    return response;
  }

  Future<void> onRegisterUnregister({
    required String deviceId,
    required bool isRegister,
  }) async {
    await _restClientDio.post(
      BaseUrls.registerDevice,
      data: {
        'deviceId': deviceId,
        'isRegister': isRegister,
      },
    );
  }
}
