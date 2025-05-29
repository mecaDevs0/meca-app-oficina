import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../data/models/budget_service_model.dart';
import '../core.dart';

enum TableStyle { icon, checkBox }

class AppTablePrice extends StatelessWidget {
  const AppTablePrice({
    super.key,
    required this.services,
    this.style = TableStyle.icon,
  });

  final List<BudgetServiceModel> services;
  final TableStyle style;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.grayLineColor),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  width: 1,
                  color: AppColors.grayLineColor,
                ),
              ),
            ),
            child: const Row(
              children: [
                Text(
                  'Serviços',
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Spacer(),
                Text(
                  'Preço',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          ListView.builder(
            itemCount: services.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              final service = services[index];
              final isLast = index == services.length - 1;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: !isLast
                      ? const Border(
                          bottom: BorderSide(
                            width: 1,
                            color: AppColors.grayLineColor,
                          ),
                        )
                      : null,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          service.title ?? '',
                          style: const TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          service.value?.moneyFormat() ?? r'R$ 0,00',
                          style: const TextStyle(
                            color: AppColors.abbey,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      service.description ?? '',
                      style: const TextStyle(
                        color: AppColors.boulder,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
