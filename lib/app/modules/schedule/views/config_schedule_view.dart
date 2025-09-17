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
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Skeletonizer(
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
              ),
            ),
            // Botão sempre visível na parte inferior
            Container(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: MegaBaseButton(
                  'Salvar Configuração',
                  onButtonPress: () async {
                    final result = await controller.saveConfigSchedule();
                    if (result) {
                      MegaSnackbar.showSuccessSnackBar(
                        'Agenda salva com sucesso',
                      );
                      // Voltar para a home após salvar
                      Get.offAllNamed('/home');
                    }
                  },
                  isLoading: controller.isLoading,
                  backgroundColor: AppColors.primary,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
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
                    // Horários de funcionamento
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: Colors.green[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Horários de Funcionamento (Obrigatório)',
                                style: TextStyle(
                                  color: Colors.green[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TimerWidget(
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
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TimerWidget(
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Horários de pausa (opcional)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue[200]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.coffee,
                                color: Colors.blue[600],
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Período de Pausa (Opcional)',
                                style: TextStyle(
                                  color: Colors.blue[600],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'OPCIONAL',
                                  style: TextStyle(
                                    color: Colors.blue[700],
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Configure os horários de pausa se desejar. Deixe em branco se não houver pausa.',
                            style: TextStyle(
                              color: Colors.blue[600],
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TimerWidget(
                                  title: 'Início da Pausa',
                                  hint: 'Ex: 12:00 (opcional)',
                                  value: weekDay.startOfBreak,
                                  isOptional: true,
                                  onChanged: (value) {
                                    controller.setTime(
                                      typeTime: TypeTimeAgenda.startOfBreak,
                                      day: day,
                                      value: value,
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: TimerWidget(
                                  title: 'Fim da Pausa',
                                  hint: 'Ex: 13:00 (opcional)',
                                  value: weekDay.endOfBreak,
                                  onChanged: (value) {
                                    controller.setTime(
                                      typeTime: TypeTimeAgenda.endOfBreak,
                                      day: day,
                                      value: value,
                                    );
                                  },
                                  isOptional: true,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Botão para limpar pausa
                          Center(
                            child: ElevatedButton.icon(
                              onPressed: weekDay.startOfBreak.isNotEmpty || weekDay.endOfBreak.isNotEmpty
                                  ? () {
                                      controller.setTime(
                                        typeTime: TypeTimeAgenda.startOfBreak,
                                        day: day,
                                        value: '',
                                      );
                                      controller.setTime(
                                        typeTime: TypeTimeAgenda.endOfBreak,
                                        day: day,
                                        value: '',
                                      );
                                    }
                                  : null,
                              icon: Icon(
                                Icons.clear,
                                size: 18,
                                color: Colors.white,
                              ),
                              label: Text(
                                'Limpar Pausa',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red[400],
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
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
