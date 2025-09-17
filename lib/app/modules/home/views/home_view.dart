import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFFAFAFA),
      body: Obx(
        () => RefreshIndicator(
          onRefresh: controller.onRefresh,
          child: CustomScrollView(
            slivers: [
              // Header section
              SliverToBoxAdapter(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome section
                      Text(
                        'Bem-vindo de volta!',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: AppColors.fontDarkGray,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Gerencie seus agendamentos e serviços',
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: AppColors.grayMedium,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Banners section
                      if (_isDataBankInvalid || _isAgendaInvalid || _isServiceInvalid || controller.listIssues.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: AppColors.grayBorderColor,
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              if (_isDataBankInvalid) ...[
                                _buildBannerItem(
                                  icon: Icons.account_balance,
                                  title: 'Conta bancária',
                                  subtitle: 'Configure sua conta para receber pagamentos',
                                  onTap: () async {
                                    final result = await Get.toNamed(Routes.bankAccount);
                                    if (result == true) {
                                      await controller.onGetWorkshopInfo();
                                    }
                                  },
                                ),
                                if (_isAgendaInvalid || _isServiceInvalid || controller.listIssues.isNotEmpty)
                                  const SizedBox(height: 16),
                              ],
                              if (_isAgendaInvalid) ...[
                                _buildBannerItem(
                                  icon: Icons.schedule,
                                  title: 'Configurar agenda',
                                  subtitle: 'Defina seus horários de atendimento',
                                  onTap: () => Get.toNamed(Routes.configSchedule),
                                ),
                                if (_isServiceInvalid || controller.listIssues.isNotEmpty)
                                  const SizedBox(height: 16),
                              ],
                              if (_isServiceInvalid) ...[
                                _buildBannerItem(
                                  icon: Icons.build,
                                  title: 'Serviços',
                                  subtitle: 'Adicione os serviços que você oferece',
                                  onTap: () => Get.toNamed(Routes.createService),
                                ),
                                if (controller.listIssues.isNotEmpty)
                                  const SizedBox(height: 16),
                              ],
                              if (controller.listIssues.isNotEmpty)
                                _buildBannerItem(
                                  icon: Icons.assignment,
                                  title: 'Requisitos pendentes',
                                  subtitle: 'Complete seus dados para ativar sua conta',
                                  onTap: () async {
                                    final isResult = await Get.toNamed(Routes.requirementsForm);
                                    if (isResult == true) {
                                      await controller.onGetWorkshopInfo();
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      
                      const SizedBox(height: 24),
                      
                      // Tabs section
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.grayBorderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
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
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Date picker section
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.grayBorderColor,
                            width: 1,
                          ),
                        ),
                        child: AppDataPicker(
                          label: 'Filtrar por data',
                          hintText: 'Selecione o período',
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
                      ),
                      
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Content section
              switch (controller.selectedTab) {
                HomeSection.upcoming => const NextTabView(),
                HomeSection.history => const HistoricTabView(),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBannerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primaryColor.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: AppColors.primaryColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.fontDarkGray,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: AppColors.grayMedium,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppColors.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
