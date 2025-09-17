import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/app_colors.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../controllers/schedule_controller.dart';
import 'widgets/schedule_calendar.dart';
import 'widgets/schedule_item.dart';

class ScheduleView extends GetView<ScheduleController> {
  const ScheduleView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const ScheduleCalendar(),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryColor, AppColors.primaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: MegaBaseButton(
                'Configurar agenda',
                onButtonPress: () => Get.toNamed(Routes.configSchedule),
                borderRadius: 16,
                buttonColor: Colors.transparent,
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ).animate().fadeIn(
                  begin: 0,
                  duration: const Duration(milliseconds: 500),
                ),
            const SizedBox(height: 24),
            Obx(() {
              if (controller.isLoading) {
                final schedule = WorkshopAgendaModel(
                  available: false,
                  hour: '00:00',
                  profile: ProfileModel(
                    fullName: 'Carregando...',
                    phone: 'Carregando...',
                  ),
                );
                final fakeList = List.filled(
                  6,
                  ScheduleItem(schedule: schedule),
                );
                return Skeletonizer(
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: fakeList.length,
                    itemBuilder: (context, index) {
                      return fakeList[index];
                    },
                  ),
                );
              }
              if (controller.schedule == null) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text(
                      'Configure sua agenda para visualizar seus serviços',
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }
              if (controller.schedule?.workshopAgenda.isEmpty ?? true) {
                return const Padding(
                  padding: EdgeInsets.only(top: 24),
                  child: Center(
                    child: Text('Sua agenda para este dia está vazia'),
                  ),
                );
              }
              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.schedule?.workshopAgenda.length ?? 0,
                itemBuilder: (context, index) {
                  final item = controller.schedule?.workshopAgenda[index];
                  if (item == null) {
                    return const SizedBox.shrink();
                  }
                  return ScheduleItem(schedule: item);
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}
