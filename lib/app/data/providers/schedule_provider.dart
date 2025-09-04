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
    try {
      print('✅ Fazendo requisição para WorkshopAgenda/$id');
      final response = await _restClientDio.get('${BaseUrls.agenda}/$id');
      
      if (response.data == null || response.data['erro'] == true) {
        print('⚠️ Agenda não encontrada, retornando agenda inicial');
        return AgendaModel.initial();
      }
      
      // Verificar se os campos dos dias são null
      final data = response.data['data'] ?? response.data;
      if (data == null) {
        print('⚠️ Dados da agenda são null, retornando agenda inicial');
        return AgendaModel.initial();
      }
      
      // Verificar se pelo menos um campo dos dias tem dados válidos
      final days = ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
      bool hasValidData = false;
      for (final day in days) {
        if (data[day] != null && data[day] is Map) {
          final dayData = data[day] as Map;
          if (dayData['open'] == true || 
              (dayData['startTime'] != null && dayData['startTime'].toString().isNotEmpty) ||
              (dayData['closingTime'] != null && dayData['closingTime'].toString().isNotEmpty)) {
            hasValidData = true;
            break;
          }
        }
      }
      
      if (!hasValidData) {
        print('⚠️ Nenhum dia tem dados válidos, retornando agenda inicial');
        return AgendaModel.initial();
      }
      
      try {
        return AgendaModel.fromJson(data);
      } catch (e) {
        print('⚠️ Erro ao fazer parse da agenda, retornando agenda inicial: $e');
        return AgendaModel.initial();
      }
    } catch (e) {
      print('❌ Erro ao buscar agenda: $e');
      // Retornar agenda inicial em caso de erro
      return AgendaModel.initial();
    }
  }

  Future<AgendaModel> saveConfigSchedule(AgendaModel agenda) async {
    try {
      // Adicionar workshopId ao payload
      final workshop = WorkshopModel.fromCache();
      if (workshop.id.isNullOrEmpty) {
        throw Exception('Workshop ID não encontrado');
      }
      
      final agendaData = agenda.toJson();
      agendaData['workshopId'] = workshop.id;
      
      print('🔧 Salvando agenda com workshopId: ${workshop.id}');
      print('📋 Dados da agenda: $agendaData');
      
      final response = await _restClientDio.patch(
        BaseUrls.agenda,
        data: agendaData,
      );
      
      if (response.data != null && response.data['erro'] == true) {
        throw Exception(response.data['message'] ?? 'Erro ao salvar agenda');
      }
      
      // Se a API retornou sucesso mas sem dados, retornar a agenda original
      if (response.data == null) {
        print('✅ Agenda salva com sucesso, retornando agenda original');
        return agenda;
      }
      
      // Se há dados na resposta, tentar fazer o parse
      if (response.data != null) {
        try {
          return AgendaModel.fromJson(response.data);
        } catch (e) {
          print('⚠️ Erro ao fazer parse da resposta, retornando agenda original: $e');
          return agenda;
        }
      }
      
      // Se não há dados na resposta, retornar a agenda original
      print('✅ Agenda salva com sucesso, retornando agenda original');
      return agenda;
    } catch (e) {
      print('❌ Erro ao salvar agenda: $e');
      rethrow;
    }
  }
}
