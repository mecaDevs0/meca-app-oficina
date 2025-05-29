// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_service_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ScheduleServiceModel _$ScheduleServiceModelFromJson(
        Map<String, dynamic> json) =>
    ScheduleServiceModel(
      id: json['id'] as String,
      created: (json['created'] as num).toInt(),
      observations: json['observations'] as String?,
      date: (json['date'] as num).toInt(),
      suggestedDate: (json['suggestedDate'] as num?)?.toInt(),
      status: (json['status'] as num).toInt(),
      budgetApprovalDate: (json['budgetApprovalDate'] as num?)?.toInt(),
      estimatedTimeForCompletion:
          (json['estimatedTimeForCompletion'] as num?)?.toInt(),
      diagnosticValue: (json['diagnosticValue'] as num?)?.toDouble(),
      budgetImages: (json['budgetImages'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      totalValue: (json['totalValue'] as num?)?.toDouble(),
      workshopServices: (json['workshopServices'] as List<dynamic>?)
              ?.map((e) =>
                  WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      maintainedBudgetServices:
          (json['maintainedBudgetServices'] as List<dynamic>?)
                  ?.map((e) =>
                      WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
                  .toList() ??
              [],
      excludedBudgetServices: (json['excludedBudgetServices'] as List<dynamic>?)
              ?.map((e) =>
                  WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      paymentDate: (json['paymentDate'] as num?)?.toInt(),
      paymentStatus: (json['paymentStatus'] as num?)?.toInt(),
      serviceStartDate: (json['serviceStartDate'] as num?)?.toInt(),
      serviceEndDate: (json['serviceEndDate'] as num?)?.toInt(),
      reasonDisapproval: json['reasonDisapproval'] as String?,
      imagesDisapproval: (json['imagesDisapproval'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dispute: json['dispute'] as String?,
      imagesDispute: (json['imagesDispute'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      freeRepair: json['freeRepair'] as bool,
      serviceFinishedByAdmin: json['serviceFinishedByAdmin'] as bool?,
      profile: ProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      workshop:
          WorkshopModel.fromJson(json['workshop'] as Map<String, dynamic>),
      vehicle: VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
      awaitFreeRepairScheduling: json['awaitFreeRepairScheduling'] as bool,
      budgetServices: (json['budgetServices'] as List<dynamic>?)
          ?.map((e) => BudgetServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      lastUpdate: (json['lastUpdate'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ScheduleServiceModelToJson(
        ScheduleServiceModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'created': instance.created,
      'observations': instance.observations,
      'date': instance.date,
      'suggestedDate': instance.suggestedDate,
      'status': instance.status,
      'budgetApprovalDate': instance.budgetApprovalDate,
      'estimatedTimeForCompletion': instance.estimatedTimeForCompletion,
      'diagnosticValue': instance.diagnosticValue,
      'budgetImages': instance.budgetImages,
      'totalValue': instance.totalValue,
      'workshopServices': instance.workshopServices,
      'maintainedBudgetServices': instance.maintainedBudgetServices,
      'excludedBudgetServices': instance.excludedBudgetServices,
      'paymentDate': instance.paymentDate,
      'paymentStatus': instance.paymentStatus,
      'serviceStartDate': instance.serviceStartDate,
      'serviceEndDate': instance.serviceEndDate,
      'reasonDisapproval': instance.reasonDisapproval,
      'imagesDisapproval': instance.imagesDisapproval,
      'dispute': instance.dispute,
      'imagesDispute': instance.imagesDispute,
      'freeRepair': instance.freeRepair,
      'serviceFinishedByAdmin': instance.serviceFinishedByAdmin,
      'profile': instance.profile,
      'workshop': instance.workshop,
      'vehicle': instance.vehicle,
      'lastUpdate': instance.lastUpdate,
      'awaitFreeRepairScheduling': instance.awaitFreeRepairScheduling,
      'budgetServices': instance.budgetServices,
    };
