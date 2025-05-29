// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleModel _$ScheduleModelFromJson(Map<String, dynamic> json) =>
    ScheduleModel(
      date: DateTime.parse(json['date'] as String),
      available: json['available'] as bool,
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      hours: (json['hours'] as List<dynamic>).map((e) => e as String).toList(),
      workshopAgenda: (json['workshopAgenda'] as List<dynamic>)
          .map((e) => WorkshopAgendaModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ScheduleModelToJson(ScheduleModel instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'available': instance.available,
      'dayOfWeek': instance.dayOfWeek,
      'hours': instance.hours,
      'workshopAgenda': instance.workshopAgenda,
    };
