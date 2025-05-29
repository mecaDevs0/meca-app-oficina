import 'package:json_annotation/json_annotation.dart';

import 'models.dart';

part 'financial_model.g.dart';

@JsonSerializable()
class FinancialModel {
  FinancialModel({
    required this.profile,
    required this.workshop,
    required this.workshopServices,
    required this.vehicle,
    required this.schedulingId,
    required this.value,
    required this.netValue,
    required this.processingValue,
    required this.mechanicalNetValue,
    required this.paymentDate,
    required this.releasedDate,
    required this.expiredDate,
    required this.refundDate,
    required this.reversedValue,
    required this.platformFee,
    required this.platformValue,
    required this.installment,
    required this.creditCardId,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.invoiceId,
    required this.pixQrCode,
    required this.pixQrCodeTxt,
    required this.created,
    required this.id,
  });

  factory FinancialModel.fromJson(Map<String, dynamic> json) {
    return _$FinancialModelFromJson(json);
  }

  final ProfileModel profile;
  final WorkshopModel workshop;
  final List<WorkshopServiceModel> workshopServices;
  final VehicleModel vehicle;
  final String schedulingId;
  @JsonKey(defaultValue: 0.0)
  final double value;
  @JsonKey(defaultValue: 0.0)
  final double netValue;
  @JsonKey(defaultValue: 0.0)
  final double processingValue;
  @JsonKey(defaultValue: 0.0)
  final double mechanicalNetValue;
  final int? paymentDate;
  final int? releasedDate;
  final int? expiredDate;
  final int? refundDate;
  @JsonKey(defaultValue: 0.0)
  final double reversedValue;
  @JsonKey(defaultValue: 0.0)
  final double platformFee;
  @JsonKey(defaultValue: 0.0)
  final double platformValue;
  final int installment;
  final String? creditCardId;
  final int paymentStatus;
  final int paymentMethod;
  @JsonKey(defaultValue: '')
  final String invoiceId;
  final String? pixQrCode;
  final String? pixQrCodeTxt;
  final int created;
  final String id;

  Map<String, dynamic> toJson() => _$FinancialModelToJson(this);
}
