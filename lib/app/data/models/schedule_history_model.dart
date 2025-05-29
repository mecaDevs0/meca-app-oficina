import 'package:json_annotation/json_annotation.dart';

part 'schedule_history_model.g.dart';

@JsonSerializable()
class ScheduleHistoryModel {
  ScheduleHistoryModel({
    required this.statusTitle,
    required this.status,
    this.description,
    this.schedulingId,
    this.created,
    required this.id,
  });

  factory ScheduleHistoryModel.fromJson(Map<String, dynamic> json) {
    return _$ScheduleHistoryModelFromJson(json);
  }

  int statusTitle;
  int status;
  String? description;
  String? schedulingId;
  int? created;
  String id;

  Map<String, dynamic> toJson() => _$ScheduleHistoryModelToJson(this);
}
