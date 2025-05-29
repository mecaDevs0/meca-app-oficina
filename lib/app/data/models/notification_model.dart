import 'package:json_annotation/json_annotation.dart';

import '../data.dart';

part 'notification_model.g.dart';

@JsonSerializable()
class NotificationModel {
  NotificationModel({
    required this.title,
    required this.content,
    required this.dateRead,
    required this.workshop,
    required this.profile,
    required this.created,
    required this.id,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return _$NotificationModelFromJson(json);
  }

  final String title;
  final String content;
  final int? dateRead;
  final WorkshopModel? workshop;
  final ProfileModel? profile;
  final int created;
  final String id;

  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}

extension DateTimeExtension on DateTime {
  bool isSameDate(DateTime other) {
    return year == other.year && month == other.month && day == other.day;
  }
}
