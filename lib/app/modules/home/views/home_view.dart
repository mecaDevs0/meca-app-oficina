import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../controllers/home_controller.dart';
import 'historic_tab_view.dart';
import 'next_tab_view.dart';
import 'widgets/tab_item.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends MegaState<HomeView, HomeController> {
  final dateController = TextEditingController();

  bool get _isDataBankInvalid {
    return controller.workshop?.dataBankValid != true;
  }

  bool get _isAgendaInvalid {
    return controller.workshop?.workshopAgendaValid != true;
  }

  bool get _isServiceInvalid {
    return controller.workshop?.workshopServicesValid != true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(
        () => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(
                  children: [
                    Visibility(
                      visible: _isDataBankInvalid,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () async {
                              final result =
                                  await Get.toNamed(Routes.bankAccount);
                              if (result == true) {
                                await controller.onGetWorkshopInfo();
                              }
                            },
                            child: SvgPicture.asset(AppImages.bannerBank),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _isAgendaInvalid,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => Get.toNamed(Routes.configSchedule),
                            child: SvgPicture.asset(AppImages.bannerSchedule),
                          ),
                          const SizedBox(
                            height: 24,
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: _isServiceInvalid,
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () => Get.toNamed(Routes.createService),
                            child: SvgPicture.asset(AppImages.bannerService),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: controller.listIssues.isNotEmpty,
                      child: InkWell(
                        onTap: () async {
                          final isResult =
                              await Get.toNamed(Routes.requirementsForm);
                          if (isResult == true) {
                            await controller.onGetWorkshopInfo();
                          }
                        },
                        child:
                            SvgPicture.asset(AppImages.bannerRecognitionData),
                      ),
                    ),
                    Row(
                      children: HomeSection.values
                          .map(
                            (tab) => TabItem(
                              onTap: () => controller.selectedTab = tab,
                              homeTab: tab,
                              selectedTab: controller.selectedTab,
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 24),
                    AppDataPicker(
                      label: 'Busque pro data',
                      hintText: 'Selecione a data',
                      selectedStartDate: controller.filterStartDate,
                      selectedEndDate: controller.filterEndDate,
                      onApplyClick: (startDate, endDate) {
                        controller.startDate = startDate;
                        if (endDate != null) {
                          controller.endDate = endDate;
                        } else {
                          controller.endDate = startDate;
                        }
                        controller.nextPagingController.refresh();
                        controller.historyPagingController.refresh();
                      },
                      onCancelClick: () {
                        controller.startDate = null;
                        controller.endDate = null;
                        controller.nextPagingController.refresh();
                        controller.historyPagingController.refresh();
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            switch (controller.selectedTab) {
              HomeSection.upcoming => const NextTabView(),
              HomeSection.history => const HistoricTabView(),
            },
          ],
        ),
      ),
    );
  }
}
