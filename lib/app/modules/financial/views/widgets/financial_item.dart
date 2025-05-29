import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';
import '../../../../routes/app_pages.dart';

class FinancialItem extends StatelessWidget {
  const FinancialItem({
    super.key,
    required this.financial,
  });

  final FinancialModel financial;

  String get _getDate {
    return financial.paymentDate?.toddMMyy() ?? 'não informada';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Get.toNamed(
          Routes.serviceDetails,
          arguments: ServiceArgs(financial.schedulingId),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(width: 1, color: AppColors.mercury),
            borderRadius: BorderRadius.circular(8),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x0C000000),
              blurRadius: 4,
              offset: Offset(0, 2),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  financial.profile.fullName ?? '',
                  style: const TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  financial.mechanicalNetValue.moneyFormat(),
                  style: const TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            AppCarDesc(
              isVisibleTitle: false,
              vehicle: financial.vehicle,
            ),
            Row(
              children: [
                Text(
                  'Serviço pago $_getDate',
                  style: const TextStyle(
                    color: AppColors.hintTextColor,
                    fontSize: 12,
                  ),
                ),
                const Spacer(),
                const Text(
                  'Ver detalhes',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(width: 4),
                SvgPicture.asset(
                  AppImages.icArrow,
                  colorFilter: const ColorFilter.mode(
                    AppColors.caribbeanGreen,
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
