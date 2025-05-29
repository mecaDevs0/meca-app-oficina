import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';
import '../../../schedule/views/widgets/body_modal_timer.dart';
import '../../controllers/service_details_controller.dart';
import 'container_buttons.dart';

class BottomActions extends GetView<ServiceDetailsController> {
  const BottomActions({super.key});

  ScheduleStatus get _getStatus {
    final index = controller.scheduleService.status;
    return ScheduleStatus.values[index];
  }

  String _validTime(String time) {
    return time.isNullOrEmpty ? '00:00' : time;
  }

  void _showModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      backgroundColor: Colors.white,
      builder: (context) {
        final formKey = GlobalKey<FormState>();
        final dateController = TextEditingController();
        final timeController = TextEditingController();

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Sugerir outro horário',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Data',
                  hintText: 'Nova data',
                  controller: dateController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    DataInputFormatter(),
                  ],
                  onTap: () {
                    showMegaDatePicker(
                      context,
                      minimumDate: DateTime.now(),
                      maximumDate:
                          DateTime.now().add(const Duration(days: 365)),
                      onSelectDate: (date) {
                        dateController.text = date.toddMMyyyy();
                      },
                      onCancelClick: () {
                        dateController.clear();
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Hora',
                  hintText: 'Nova hora',
                  controller: timeController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    HoraInputFormatter(),
                  ],
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => Material(
                        color: Colors.transparent,
                        child: BodyModalTimer(
                          value: _validTime(timeController.text),
                          onChanged: (value) {
                            timeController.text = value;
                          },
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: MegaBaseButton(
                        'Cancelar',
                        textStyle: AppTextStyle.buttonTextStyle.copyWith(
                          color: AppColors.primaryColor,
                        ),
                        borderRadius: 4,
                        border: Border.all(
                          color: AppColors.grayLineColor,
                          width: 1,
                        ),
                        buttonColor: Colors.white,
                        onButtonPress: Get.back,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MegaBaseButton(
                        'Enviar',
                        isLoading: controller.isLoadingConfirm,
                        textStyle: AppTextStyle.buttonTextStyle,
                        borderRadius: 4,
                        onButtonPress: () async {
                          if (formKey.currentState?.validate() == false) {
                            return;
                          }
                          final date = dateController.text;
                          final time = timeController.text;
                          final stringDate = '$date $time:00';
                          final dateTime = stringDate.toDateTime;
                          if (dateTime == null) {
                            MegaSnackbar.showErroSnackBar(
                              'Data e hora inválida',
                            );
                            return;
                          }
                          FocusScope.of(context).unfocus();
                          Get.back();
                          await controller.suggestNewTime(dateTime);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => switch (_getStatus) {
        ScheduleStatus.waitingScheduling => () {
            if (controller.scheduleService.awaitFreeRepairScheduling == false) {
              return ContainerButtons(
                buttons: [
                  MegaBaseButton(
                    'Confirmar',
                    textStyle: AppTextStyle.buttonTextStyle,
                    borderRadius: 4,
                    onButtonPress: () async {
                      await controller.confirmSchedule();
                    },
                    isLoading: controller.isLoadingConfirm,
                  ),
                  const SizedBox(height: 16),
                  MegaBaseButton(
                    'Cancelar',
                    isLoading: controller.isLoadingCancel,
                    buttonColor: AppColors.apricot,
                    textStyle: AppTextStyle.buttonTextStyle,
                    borderRadius: 4,
                    onButtonPress: () async {
                      await controller.cancelSchedule();
                    },
                  ),
                  const SizedBox(height: 16),
                  MegaBaseButton(
                    'Sugerir outro horário',
                    isLoading: controller.isLoadingConfirm,
                    buttonColor: Colors.white,
                    textStyle: AppTextStyle.secondaryButtonTextStyle,
                    border: Border.all(
                      color: AppColors.grayLineColor,
                      width: 2,
                    ),
                    borderRadius: 4,
                    onButtonPress: () => _showModal(context),
                  ),
                ],
              );
            }
            return const SizedBox.shrink();
          }(),
        ScheduleStatus.scheduled => ContainerButtons(
            buttons: [
              MegaBaseButton(
                'Confirmar chegada',
                isLoading: controller.isLoadingConfirmArrival,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(5);
                },
              ),
              const SizedBox(height: 16),
              MegaBaseButton(
                'Não compareceu',
                isLoading: controller.isLoadingClientDidNotShowUp,
                buttonColor: AppColors.apricot,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(4);
                },
              ),
            ],
          ),
        ScheduleStatus.waitingBudget => ContainerButtons(
            buttons: [
              MegaBaseButton(
                'Enviar orçamento',
                isLoading: controller.isLoadingConfirm,
                buttonColor: AppColors.primaryColor,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  Get.toNamed(
                    Routes.sendQuote,
                    arguments: {'id': controller.scheduleService.id},
                  );
                },
              ),
            ],
          ),
        ScheduleStatus.waitingStart => ContainerButtons(
            buttons: [
              MegaBaseButton(
                'Iniciar serviço',
                isLoading: controller.isLoadingConfirm,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(16);
                },
              ),
              const SizedBox(height: 16),
              MegaBaseButton(
                'Aguardando peça',
                isLoading: controller.isLoadingConfirm,
                textStyle: AppTextStyle.buttonTextStyle.copyWith(
                  color: AppColors.primaryColor,
                ),
                borderRadius: 4,
                border: Border.all(
                  color: AppColors.grayLineColor,
                  width: 2,
                ),
                buttonColor: Colors.white,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(17);
                },
              ),
            ],
          ),
        ScheduleStatus.waitingParts => ContainerButtons(
            buttons: [
              MegaBaseButton(
                'Continuar serviço',
                isLoading: controller.isLoadingConfirm,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(16);
                },
              ),
            ],
          ),
        ScheduleStatus.serviceInProgress => ContainerButtons(
            buttons: [
              MegaBaseButton(
                'Finalizar serviço',
                isLoading: controller.isLoadingConfirm,
                textStyle: AppTextStyle.buttonTextStyle,
                borderRadius: 4,
                onButtonPress: () async {
                  await controller.changeScheduleStatus(18);
                },
              ),
            ],
          ),
        _ => const SizedBox.shrink(),
      },
    );
  }
}
