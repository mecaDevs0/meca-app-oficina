import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../../../routes/app_pages.dart';
import '../../financial/bindings/financial_binding.dart';
import '../../financial/views/financial_view.dart';
import '../../home/bindings/home_binding.dart';
import '../../home/views/home_view.dart';
import '../../profile/bindings/profile_binding.dart';
import '../../profile/views/profile_view.dart';
import '../../schedule/bindings/schedule_binding.dart';
import '../../schedule/views/schedule_view.dart';
import '../controllers/core_controller.dart';
import 'widgets/bottom_bar_item.dart';
import 'widgets/core_app_bar.dart';

class CoreView extends StatefulWidget {
  const CoreView({super.key});

  @override
  State<CoreView> createState() => _CoreViewState();
}

class _CoreViewState extends MegaState<CoreView, CoreController> {
  @override
  void initState() {
    ever(controller.hasRequestPermission, (bool hasPermission) {
      if (!hasPermission) {
        AppBottomSheet.showLocationBottomSheet(
          context,
          onRequestPermission: controller.requestPermission,
        );
      }
    });
    super.initState();
  }

  final pages = <String>[
    Routes.home,
    Routes.schedule,
    Routes.financial,
    Routes.profile,
  ];

  Route? onGenerateRoute(RouteSettings settings) {
    return switch (settings.name) {
      Routes.home => GetPageRoute(
          settings: settings,
          page: () => const HomeView(),
          binding: HomeBinding(),
          curve: Curves.easeIn,
          transition: Transition.fadeIn,
          popGesture: false,
        ),
      Routes.schedule => GetPageRoute(
          settings: settings,
          page: () => const ScheduleView(),
          binding: ScheduleBinding(),
          curve: Curves.easeIn,
          transition: Transition.fadeIn,
          popGesture: false,
        ),
      Routes.financial => GetPageRoute(
          settings: settings,
          page: () => const FinancialView(),
          binding: FinancialBinding(),
          curve: Curves.easeIn,
          transition: Transition.fadeIn,
          popGesture: false,
        ),
      Routes.profile => GetPageRoute(
          settings: settings,
          page: () => const ProfileView(),
          binding: ProfileBinding(),
          curve: Curves.easeIn,
          transition: Transition.fadeIn,
          popGesture: false,
        ),
      _ => null,
    };
  }

  void changePage(int index) {
    if (controller.currentIndex == index) {
      return;
    }
    controller.currentIndex = index;
    Get.offNamedUntil(
      pages[controller.currentIndex],
      (route) => route.settings.name == Routes.home,
      id: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: const CoreAppBar(),
          body: Navigator(
            key: Get.nestedKey(1),
            initialRoute: Routes.home,
            onGenerateRoute: onGenerateRoute,
          ),
          bottomNavigationBar: Container(
            height: 88,
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x19000000),
                  blurRadius: 4,
                  offset: Offset.zero,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: NavigationTab.values.map((item) {
                return BottomBarItem(
                  bottomBarEnum: item,
                  onTap: () => changePage(item.index),
                );
              }).toList(),
            ),
          ),
        ),
        Obx(
          () => Visibility(
            visible: controller.isLoading,
            child: Container(
              color: Colors.black.withValues(alpha: 0.6),
              child: Center(
                child: Card(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 16,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppColors.primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          controller.loadingMessage,
                          style: const TextStyle(
                            color: AppColors.abbey,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
