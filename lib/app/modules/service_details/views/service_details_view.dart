import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/service_details_controller.dart';
import 'widgets/bottom_actions.dart';
import 'widgets/schedule_historic.dart';
import 'widgets/service_info.dart';
import 'widgets/service_title.dart';

class ServiceDetailsView extends StatefulWidget {
  const ServiceDetailsView({super.key});

  @override
  State<ServiceDetailsView> createState() => _ServiceDetailsViewState();
}

class _ServiceDetailsViewState
    extends MegaState<ServiceDetailsView, ServiceDetailsController> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Detalhes do serviço'),
      body: Obx(() {
        if (controller.isLoading) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 8),
                Text('Buscando detalhes do serviço...'),
              ],
            ),
          );
        }
        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppClientInfo(
                      name: controller.scheduleService.profile.fullName ?? '',
                      email: controller.scheduleService.profile.email ?? '',
                    ),
                    const SizedBox(height: 12),
                    const ServiceInfo(),
                    const SizedBox(height: 8),
                    const ServiceTitle(
                      title: 'Histórico do serviço',
                    ),
                    const SizedBox(height: 16),
                    ScheduleHistoric(
                      scrollController: _scrollController,
                    ),
                  ],
                ),
              ),
            ),
            const BottomActions(),
          ],
        );
      }),
    );
  }
}
