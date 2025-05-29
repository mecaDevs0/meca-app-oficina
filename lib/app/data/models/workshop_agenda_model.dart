import 'package:json_annotation/json_annotation.dart';

import '../data.dart';

part 'workshop_agenda_model.g.dart';

@JsonSerializable()
class WorkshopAgendaModel {
  WorkshopAgendaModel({
    required this.available,
    required this.hour,
    this.profile,
    this.vehicle,
  });

  factory WorkshopAgendaModel.fromJson(Map<String, dynamic> json) {
    return _$WorkshopAgendaModelFromJson(json);
  }

  final bool available;
  final String hour;
  final ProfileModel? profile;
  final VehicleModel? vehicle;

  Map<String, dynamic> toJson() => _$WorkshopAgendaModelToJson(this);

  WorkshopAgendaModel copyWith({
    bool? available,
    String? hour,
    ProfileModel? profile,
    VehicleModel? vehicle,
  }) {
    return WorkshopAgendaModel(
      available: available ?? this.available,
      hour: hour ?? this.hour,
      profile: profile ?? this.profile,
      vehicle: vehicle ?? this.vehicle,
    );
  }
}
