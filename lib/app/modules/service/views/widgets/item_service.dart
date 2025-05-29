import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';

class ItemService extends StatelessWidget {
  const ItemService({
    super.key,
    required this.service,
    required this.onTap,
  });

  final ServiceModel service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 1,
              color: AppColors.mercury,
            ),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              service.service?.name ?? '',
              style: const TextStyle(
                color: AppColors.abbey,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              service.description ?? 'Sem descrição',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.abbey,
                fontSize: 12,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Configurar valor e prazo',
                  style: TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 12,
                    decoration: TextDecoration.underline,
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
