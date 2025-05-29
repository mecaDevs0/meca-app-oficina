// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'financial_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FinancialModel _$FinancialModelFromJson(Map<String, dynamic> json) =>
    FinancialModel(
      profile: ProfileModel.fromJson(json['profile'] as Map<String, dynamic>),
      workshop:
          WorkshopModel.fromJson(json['workshop'] as Map<String, dynamic>),
      workshopServices: (json['workshopServices'] as List<dynamic>)
          .map((e) => WorkshopServiceModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      vehicle: VehicleModel.fromJson(json['vehicle'] as Map<String, dynamic>),
      schedulingId: json['schedulingId'] as String,
      value: (json['value'] as num?)?.toDouble() ?? 0.0,
      netValue: (json['netValue'] as num?)?.toDouble() ?? 0.0,
      processingValue: (json['processingValue'] as num?)?.toDouble() ?? 0.0,
      mechanicalNetValue:
          (json['mechanicalNetValue'] as num?)?.toDouble() ?? 0.0,
      paymentDate: (json['paymentDate'] as num?)?.toInt(),
      releasedDate: (json['releasedDate'] as num?)?.toInt(),
      expiredDate: (json['expiredDate'] as num?)?.toInt(),
      refundDate: (json['refundDate'] as num?)?.toInt(),
      reversedValue: (json['reversedValue'] as num?)?.toDouble() ?? 0.0,
      platformFee: (json['platformFee'] as num?)?.toDouble() ?? 0.0,
      platformValue: (json['platformValue'] as num?)?.toDouble() ?? 0.0,
      installment: (json['installment'] as num).toInt(),
      creditCardId: json['creditCardId'] as String?,
      paymentStatus: (json['paymentStatus'] as num).toInt(),
      paymentMethod: (json['paymentMethod'] as num).toInt(),
      invoiceId: json['invoiceId'] as String? ?? '',
      pixQrCode: json['pixQrCode'] as String?,
      pixQrCodeTxt: json['pixQrCodeTxt'] as String?,
      created: (json['created'] as num).toInt(),
      id: json['id'] as String,
    );

Map<String, dynamic> _$FinancialModelToJson(FinancialModel instance) =>
    <String, dynamic>{
      'profile': instance.profile,
      'workshop': instance.workshop,
      'workshopServices': instance.workshopServices,
      'vehicle': instance.vehicle,
      'schedulingId': instance.schedulingId,
      'value': instance.value,
      'netValue': instance.netValue,
      'processingValue': instance.processingValue,
      'mechanicalNetValue': instance.mechanicalNetValue,
      'paymentDate': instance.paymentDate,
      'releasedDate': instance.releasedDate,
      'expiredDate': instance.expiredDate,
      'refundDate': instance.refundDate,
      'reversedValue': instance.reversedValue,
      'platformFee': instance.platformFee,
      'platformValue': instance.platformValue,
      'installment': instance.installment,
      'creditCardId': instance.creditCardId,
      'paymentStatus': instance.paymentStatus,
      'paymentMethod': instance.paymentMethod,
      'invoiceId': instance.invoiceId,
      'pixQrCode': instance.pixQrCode,
      'pixQrCodeTxt': instance.pixQrCodeTxt,
      'created': instance.created,
      'id': instance.id,
    };
