import 'package:json_annotation/json_annotation.dart';

part 'workshop_service_aux_model.g.dart';

@JsonSerializable()
class WorkshopServiceAuxModel {
  WorkshopServiceAuxModel({
    this.id,
    this.name,
  });

  factory WorkshopServiceAuxModel.fromJson(Map<String, dynamic> json) {
    return _$WorkshopServiceAuxModelFromJson(json);
  }
  String? id;
  String? name;

  Map<String, dynamic> toJson() => _$WorkshopServiceAuxModelToJson(this);
}
