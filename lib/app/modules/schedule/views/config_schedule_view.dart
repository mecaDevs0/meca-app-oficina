import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../core/widgets/expanded_widget.dart';
import '../../../data/data.dart';
import '../controllers/schedule_controller.dart';
import 'widgets/timer_widget.dart';

class ConfigScheduleView extends StatefulWidget {
  const ConfigScheduleView({super.key});

  @override
  State<ConfigScheduleView> createState() => _ConfigScheduleViewState();
}

class _ConfigScheduleViewState
    extends MegaState<ConfigScheduleView, ScheduleController> {
  @override
  void initState() {
    controller.onGetConfigSchedule();
    controller.collapsedAllDays();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Configuração da agenda'),
      body: Obx(() {
        return SingleChildScrollView(
          child: Column(
            children: [
              Skeletonizer(
                enabled: controller.isLoadingConfig,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: DaysOfWeek.values
                        .map(
                          (day) => ItemWeek(
                            day: day,
                          ),
                        )
                        .toList(),
                  ),
                ).shade,
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: MegaBaseButton(
                  'Salvar',
                  onButtonPress: () async {
                    final result = await controller.saveConfigSchedule();
                    if (result) {
                      MegaSnackbar.showSuccessSnackBar(
                        'Agenda salva com sucesso',
                      );
                    }
                  },
                  isLoading: controller.isLoading,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class ItemWeek extends GetView<ScheduleController> {
  const ItemWeek({
    super.key,
    required this.day,
  });

  final DaysOfWeek day;

  WeekDayModel get weekDay {
    if (controller.agendaModel == null) {
      return WeekDayModel(
        open: false,
        startTime: '',
        closingTime: '',
        startOfBreak: '',
        endOfBreak: '',
      );
    }
    return switch (day) {
      DaysOfWeek.monday => controller.agendaModel!.monday,
      DaysOfWeek.tuesday => controller.agendaModel!.tuesday,
      DaysOfWeek.wednesday => controller.agendaModel!.wednesday,
      DaysOfWeek.thursday => controller.agendaModel!.thursday,
      DaysOfWeek.friday => controller.agendaModel!.friday,
      DaysOfWeek.saturday => controller.agendaModel!.saturday,
      DaysOfWeek.sunday => controller.agendaModel!.sunday,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: AppColors.grayBorderColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: InkWell(
                    splashColor: Colors.transparent,
                    onTap: () {
                      controller.toggleSelectedDay(day);
                    },
                    child: Row(
                      children: [
                        AppCheckBox(isSelected: controller.isSelected(day)),
                        const SizedBox(width: 8),
                        Text(
                          day.description,
                          style: const TextStyle(
                            color: AppColors.abbey,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                InkWell(
                  splashColor: Colors.transparent,
                  onTap: () => controller.toggleDay(day),
                  child: SizedBox(
                    height: 50,
                    width: 50,
                    child: Center(
                      child: AnimatedRotation(
                        turns: controller.isExpanded(day) ? 0 : 0.5,
                        duration: const Duration(milliseconds: 300),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child: SvgPicture.asset(AppImages.icChevronUp),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            ExpandedWidget(
              expand: controller.isExpanded(day),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TimerWidget(
                          title: 'Abre',
                          hint: 'Hora de inicio',
                          value: weekDay.startTime,
                          onChanged: (value) {
                            controller.setTime(
                              typeTime: TypeTimeAgenda.startTime,
                              day: day,
                              value: value,
                            );
                          },
                        ),
                        const Spacer(),
                        TimerWidget(
                          title: 'Fecha',
                          hint: 'Hora de fechar',
                          value: weekDay.closingTime,
                          onChanged: (value) {
                            controller.setTime(
                              typeTime: TypeTimeAgenda.closingTime,
                              day: day,
                              value: value,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        TimerWidget(
                          title: 'Inicio da pausa',
                          hint: 'Inicio da pausa',
                          value: weekDay.startOfBreak,
                          onChanged: (value) {
                            controller.setTime(
                              typeTime: TypeTimeAgenda.startOfBreak,
                              day: day,
                              value: value,
                            );
                          },
                        ),
                        const Spacer(),
                        TimerWidget(
                          title: 'Fim da pausa',
                          hint: 'Fim da pausa',
                          value: weekDay.endOfBreak,
                          onChanged: (value) {
                            controller.setTime(
                              typeTime: TypeTimeAgenda.endOfBreak,
                              day: day,
                              value: value,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
