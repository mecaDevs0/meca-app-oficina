import 'package:json_annotation/json_annotation.dart';

import '../data.dart';
import 'budget_service_model.dart';

part 'schedule_service_model.g.dart';

@JsonSerializable()
class ScheduleServiceModel {
  ScheduleServiceModel({
    required this.id,
    required this.created,
    this.observations,
    required this.date,
    this.suggestedDate,
    required this.status,
    this.budgetApprovalDate,
    this.estimatedTimeForCompletion,
    this.diagnosticValue,
    required this.budgetImages,
    required this.totalValue,
    required this.workshopServices,
    required this.maintainedBudgetServices,
    required this.excludedBudgetServices,
    required this.paymentDate,
    required this.paymentStatus,
    required this.serviceStartDate,
    required this.serviceEndDate,
    this.reasonDisapproval,
    required this.imagesDisapproval,
    this.dispute,
    required this.imagesDispute,
    required this.freeRepair,
    this.serviceFinishedByAdmin,
    required this.profile,
    required this.workshop,
    required this.vehicle,
    required this.awaitFreeRepairScheduling,
    this.budgetServices,
    this.lastUpdate,
  });

  ScheduleServiceModel.empty()
      : id = '',
        created = 0,
        observations = '',
        date = 0,
        suggestedDate = 0,
        status = 0,
        budgetApprovalDate = 0,
        estimatedTimeForCompletion = 0,
        diagnosticValue = 0,
        budgetImages = [],
        totalValue = 0,
        workshopServices = [],
        maintainedBudgetServices = [],
        excludedBudgetServices = [],
        paymentDate = 0,
        paymentStatus = 0,
        serviceStartDate = 0,
        serviceEndDate = 0,
        reasonDisapproval = '',
        imagesDisapproval = [],
        dispute = '',
        imagesDispute = [],
        freeRepair = false,
        serviceFinishedByAdmin = false,
        profile = ProfileModel.empty(),
        workshop = WorkshopModel.empty(),
        lastUpdate = 0,
        vehicle = VehicleModel.empty(),
        awaitFreeRepairScheduling = false,
        budgetServices = [];

  factory ScheduleServiceModel.fromJson(Map<String, dynamic> json) {
    return _$ScheduleServiceModelFromJson(json);
  }

  final String id;
  final int created;
  final String? observations;
  final int date;
  final int? suggestedDate;
  final int status;
  final int? budgetApprovalDate;
  final int? estimatedTimeForCompletion;
  final double? diagnosticValue;
  @JsonKey(defaultValue: [])
  final List<String> budgetImages;
  final double? totalValue;
  @JsonKey(defaultValue: [])
  final List<WorkshopServiceModel> workshopServices;
  @JsonKey(defaultValue: [])
  final List<WorkshopServiceModel> maintainedBudgetServices;
  @JsonKey(defaultValue: [])
  final List<WorkshopServiceModel> excludedBudgetServices;
  final int? paymentDate;
  final int? paymentStatus;
  final int? serviceStartDate;
  final int? serviceEndDate;
  final String? reasonDisapproval;
  @JsonKey(defaultValue: [])
  final List<String> imagesDisapproval;
  final String? dispute;
  @JsonKey(defaultValue: [])
  final List<String> imagesDispute;
  final bool freeRepair;
  final bool? serviceFinishedByAdmin;
  final ProfileModel profile;
  final WorkshopModel workshop;
  final VehicleModel vehicle;
  final int? lastUpdate;
  final bool awaitFreeRepairScheduling;
  final List<BudgetServiceModel>? budgetServices;

  Map<String, dynamic> toJson() => _$ScheduleServiceModelToJson(this);
}
