import 'package:json_annotation/json_annotation.dart';

import '../data.dart';

part 'schedule_model.g.dart';

@JsonSerializable()
class ScheduleModel {
  ScheduleModel({
    required this.date,
    required this.available,
    required this.dayOfWeek,
    required this.hours,
    required this.workshopAgenda,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return _$ScheduleModelFromJson(json);
  }

  final DateTime date;
  final bool available;
  final int dayOfWeek;
  final List<String> hours;
  final List<WorkshopAgendaModel> workshopAgenda;

  Map<String, dynamic> toJson() => _$ScheduleModelToJson(this);

  ScheduleModel copyWith({
    DateTime? date,
    bool? available,
    int? dayOfWeek,
    List<String>? hours,
    List<WorkshopAgendaModel>? workshopAgenda,
  }) {
    return ScheduleModel(
      date: date ?? this.date,
      available: available ?? this.available,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      hours: hours ?? this.hours,
      workshopAgenda: workshopAgenda ?? this.workshopAgenda,
    );
  }
}
