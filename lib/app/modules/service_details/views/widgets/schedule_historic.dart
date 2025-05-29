import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/widgets/expanded_widget.dart';
import '../../../../data/data.dart';
import '../../controllers/service_details_controller.dart';
import 'item_service.dart';
import 'title_expanded.dart';

class ScheduleHistoric extends StatefulWidget {
  const ScheduleHistoric({super.key, required this.scrollController});

  final ScrollController scrollController;

  @override
  State<ScheduleHistoric> createState() => _ScheduleHistoricState();
}

class _ScheduleHistoricState
    extends MegaState<ScheduleHistoric, ServiceDetailsController> {
  @override
  Widget build(BuildContext context) {
    final List<GlobalKey> keys = List.generate(
      ServiceHistoryType.values.length,
      (index) => GlobalKey(),
    );

    Future<void> checkItemPosition(int index) async {
      final scrollBox = widget.scrollController.position.context.storageContext
          .findRenderObject()! as RenderBox;
      final scrollPosition = scrollBox.localToGlobal(Offset.zero);
      final scrollBottom = scrollPosition.dy + scrollBox.size.height;
      final itemBox =
          keys[index].currentContext!.findRenderObject()! as RenderBox;
      final itemPosition = itemBox.localToGlobal(Offset.zero);
      final buttonBottom = itemPosition.dy + itemBox.size.height;
      final diff = scrollBottom - buttonBottom;
      if (diff <= 80) {
        await Future.delayed(const Duration(milliseconds: 500));
        widget.scrollController
            .jumpTo(widget.scrollController.position.pixels + 80);
      }
    }

    if (controller.scheduleHistory.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Text('Nenhum histórico encontrado'),
      );
    }

    return Obx(() {
      return Column(
        children: [
          ...controller.groupedData.entries.map((entry) {
            final int statusTitle = entry.key;
            final data = entry.value;
            final List<ScheduleHistoryModel> items = data['items'];
            return Column(
              children: [
                TitleExpanded(
                  key: keys[statusTitle],
                  quantity: data['count'],
                  serviceType: ServiceHistoryType.values[statusTitle],
                  onTap: () {
                    checkItemPosition(statusTitle);
                    controller.toggleServiceType(
                      ServiceHistoryType.values[statusTitle],
                    );
                  },
                ),
                ExpandedWidget(
                  expand: controller.isExpanded(
                    ServiceHistoryType.values[statusTitle],
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return ItemService(
                        schedule: item,
                      );
                    },
                  ),
                ),
              ],
            );
          }),
        ],
      );
    });
  }
}
