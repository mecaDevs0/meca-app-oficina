import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class ServiceDetailsProvider {
  ServiceDetailsProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<ScheduleServiceModel> onScheduleDetail(String id) async {
    final response = await _restClientDio.get('${BaseUrls.scheduling}/$id');
    return ScheduleServiceModel.fromJson(response.data);
  }

  Future<List<ScheduleHistoryModel>> onScheduleHistory(String id) async {
    final response = await _restClientDio.get(
      BaseUrls.schedulingHistory,
      queryParameters: {
        'schedulingId': id,
      },
    );
    return List<ScheduleHistoryModel>.from(
      response.data.map((schedule) => ScheduleHistoryModel.fromJson(schedule)),
    );
  }

  Future<ScheduleServiceModel> confirmSchedule(
    String schedulingId,
    int status,
  ) async {
    final response = await _restClientDio.post(
      BaseUrls.confirmSchedule,
      data: {
        'schedulingId': schedulingId,
        'confirmSchedulingstatus': status,
      },
    );

    return ScheduleServiceModel.fromJson(response.data);
  }

  Future<ScheduleServiceModel> changeScheduleStatus(
    String schedulingId,
    int status,
  ) async {
    final response = await _restClientDio.post(
      BaseUrls.changeScheduleStatus,
      data: {
        'schedulingId': schedulingId,
        'status': status,
      },
    );

    return ScheduleServiceModel.fromJson(response.data);
  }

  Future<void> suggestNewScheduleTime(String schedulingId, int date) async {
    await _restClientDio.post(
      BaseUrls.suggestNewTime,
      data: {
        'schedulingId': schedulingId,
        'date': date,
      },
    );
  }
}
