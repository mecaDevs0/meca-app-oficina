import 'package:json_annotation/json_annotation.dart';

import 'workshop_service_aux_model.dart';

part 'workshop_service_model.g.dart';

@JsonSerializable()
class WorkshopServiceModel {
  WorkshopServiceModel({
    this.id,
    this.service,
    this.minTimeScheduling,
    this.value,
    this.isApproved = true,
  });

  factory WorkshopServiceModel.fromJson(Map<String, dynamic> json) {
    return _$WorkshopServiceModelFromJson(json);
  }
  String? id;
  WorkshopServiceAuxModel? service;
  double? minTimeScheduling;
  double? value;
  @JsonKey(includeFromJson: false, includeToJson: false)
  bool isApproved;

  Map<String, dynamic> toJson() => _$WorkshopServiceModelToJson(this);
}
