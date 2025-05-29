import 'package:flutter/material.dart';

import '../../core/core.dart';

enum ScheduleStatus {
  waitingScheduling('Aguardando agendamento'),
  suggestedTime('Horário sugerido pela oficina'),
  refusedScheduling('Agendamento recusado'),
  scheduled('Agendamento confirmado'),
  didNotAttend('Cliente não compareceu'),
  schedulingFinished('Agendamento concluído'),
  waitingBudget('Aguardando orçamento'),
  budgetSent('Orçamento enviado'),
  waitingBudgetApproval('Aguardando aprovação de orçamento'),
  budgetApproved('Orçamento aprovado'),
  budgetPartiallyApproved('Orçamento aprovado parcialmente'),
  budgetRefused('Orçamento reprovado'),
  waitingPayment('Aguardando pagamento'),
  paymentApproved('Pagamento aprovado'),
  paymentRefused('Pagamento reprovado'),
  waitingStart('Aguardando início'),
  serviceInProgress('Serviço em andamento'),
  waitingParts('Aguardando peças'),
  serviceCompleted('Serviço concluído'),
  waitingServiceApproval('Aguardando aprovação do serviço'),
  serviceRefusedByUser('Serviço reprovado pelo usuário'),
  workshopDispute('Contestação da Oficina'),
  serviceApprovedByUser('Serviço aprovado pelo usuário'),
  serviceApprovedByAdmin('Serviço aprovado pelo admin'),
  servicePartiallyApprovedByAdmin('Serviço aprovado parcialmente pelo admin'),
  serviceRefusedByAdmin('Serviço reprovado pelo admin'),
  serviceFinished('Serviço finalizado');

  const ScheduleStatus(this.name);
  final String name;

  Color get color {
    return switch (this) {
      ScheduleStatus.waitingScheduling => AppColors.chetwodeBlue,
      ScheduleStatus.suggestedTime => AppColors.chetwodeBlue,
      ScheduleStatus.refusedScheduling => AppColors.apricot,
      ScheduleStatus.scheduled => AppColors.shamrock,
      ScheduleStatus.didNotAttend => AppColors.apricot,
      ScheduleStatus.schedulingFinished => AppColors.shamrock,
      ScheduleStatus.waitingBudget => AppColors.chetwodeBlue,
      ScheduleStatus.budgetSent => AppColors.shamrock,
      ScheduleStatus.waitingBudgetApproval => AppColors.chetwodeBlue,
      ScheduleStatus.budgetApproved => AppColors.shamrock,
      ScheduleStatus.budgetPartiallyApproved => AppColors.shamrock,
      ScheduleStatus.budgetRefused => AppColors.apricot,
      ScheduleStatus.waitingPayment => AppColors.chetwodeBlue,
      ScheduleStatus.paymentApproved => AppColors.shamrock,
      ScheduleStatus.paymentRefused => AppColors.apricot,
      ScheduleStatus.waitingStart => AppColors.chetwodeBlue,
      ScheduleStatus.serviceInProgress => AppColors.chetwodeBlue,
      ScheduleStatus.waitingParts => AppColors.chetwodeBlue,
      ScheduleStatus.serviceCompleted => AppColors.shamrock,
      ScheduleStatus.waitingServiceApproval => AppColors.chetwodeBlue,
      ScheduleStatus.serviceRefusedByUser => AppColors.apricot,
      ScheduleStatus.workshopDispute => AppColors.apricot,
      ScheduleStatus.serviceApprovedByUser => AppColors.shamrock,
      ScheduleStatus.serviceApprovedByAdmin => AppColors.shamrock,
      ScheduleStatus.servicePartiallyApprovedByAdmin => AppColors.shamrock,
      ScheduleStatus.serviceRefusedByAdmin => AppColors.apricot,
      ScheduleStatus.serviceFinished => AppColors.shamrock,
    };
  }

  static List<int> get nextStatus {
    return [
      0,
      1,
      3,
      6,
      8,
      12,
      15,
      16,
      17,
      19,
      20,
      21,
    ];
  }

  static List<int> get historicStatus {
    return [
      2,
      4,
      11,
      26,
    ];
  }
}
