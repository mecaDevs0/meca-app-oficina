import 'package:mega_commons/mega_commons.dart';

import '../../core/core.dart';
import '../data.dart';

class ScheduleProvider {
  ScheduleProvider({required RestClientDio restClientDio})
      : _restClientDio = restClientDio;

  final RestClientDio _restClientDio;

  Future<ScheduleModel> getSchedule(
    int selectedDate,
    String workshopId,
  ) async {
    final response = await _restClientDio.post(
      BaseUrls.availableScheduling,
      data: {
        'date': selectedDate,
        'workshopId': workshopId,
      },
    );
    return ScheduleModel.fromJson(response.data);
  }

  Future<void> deleteHour(int date) async {
    await _restClientDio.delete(
      '${BaseUrls.deleteHour}/$date',
    );
  }

  Future<AgendaModel> getConfigSchedule(String id) async {
    final response = await _restClientDio.get('${BaseUrls.agenda}/$id');
    if (response.data == null) {
      return AgendaModel.initial();
    }
    return AgendaModel.fromJson(response.data);
  }

  Future<AgendaModel> saveConfigSchedule(AgendaModel agenda) async {
    final response = await _restClientDio.patch(
      BaseUrls.agenda,
      data: agenda.toJson(),
    );
    return AgendaModel.fromJson(response.data);
  }
}
