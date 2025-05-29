import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class NotificationProvider {
  NotificationProvider({
    required RestClientDio restClientDio,
  }) : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<List<NotificationModel>> listNotification({
    required int page,
    required int limit,
    required String workshopId,
  }) async {
    final response = await _restClientDio.get(
      BaseUrls.notification,
      queryParameters: {
        'page': page,
        'limit': limit,
        'setRead': true,
        'typeReference': 2,
        'userId': workshopId,
      },
    );
    final notifications = (response.data as List)
        .map((e) => NotificationModel.fromJson(e))
        .toList();
    return notifications;
  }

  Future<NotificationModel> getNotificationDetail({
    required String notificationId,
  }) async {
    final response = await _restClientDio.get(
      '${BaseUrls.notification}/$notificationId',
    );

    return NotificationModel.fromJson(response.data);
  }

  Future<MegaResponse> removeNotification({required String notificationId}) {
    final response = _restClientDio.delete(
      '${BaseUrls.notification}/$notificationId',
    );
    return response;
  }
}
