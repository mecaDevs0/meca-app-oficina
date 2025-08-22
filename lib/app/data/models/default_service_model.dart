import 'package:json_annotation/json_annotation.dart';

part 'default_service_model.g.dart';

@JsonSerializable()
class DefaultServiceModel {
  DefaultServiceModel({
    required this.id,
    required this.name,
    this.quickService,
    this.minTimeScheduling,
    this.description,
    this.photo,
    this.dataBlocked,
    this.disabled,
    this.created,
  });

  factory DefaultServiceModel.fromJson(Map<String, dynamic> json) =>
      _$DefaultServiceModelFromJson(json);

  final String id;
  final String name;
  final bool? quickService;
  final double? minTimeScheduling;
  final String? description;
  final String? photo;
  final int? dataBlocked;
  final int? disabled;
  final int? created;

  Map<String, dynamic> toJson() => _$DefaultServiceModelToJson(this);
}
