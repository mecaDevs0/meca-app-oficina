import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';

import '../../../../core/core.dart';
import '../../../../data/data.dart';

class ItemNotification extends StatelessWidget {
  const ItemNotification({
    super.key,
    required this.notification,
    required this.removeNotification,
    required this.onTap,
  });

  final NotificationModel notification;
  final Function() removeNotification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.only(bottom: 16),
        decoration: ShapeDecoration(
          color: notification.dateRead == null
              ? AppColors.whiteIce
              : Colors.transparent,
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: notification.dateRead == null
                  ? Colors.transparent
                  : AppColors.grayLineColor,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  notification.title,
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () {
                    MegaModal.showConfirmCancel(
                      context,
                      title: 'Excluir notificação',
                      message: 'Deseja excluir esta notificação?',
                      confirmButtonColor: AppColors.primaryColor,
                      onSuccess: removeNotification,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      AppImages.icClose,
                      colorFilter: const ColorFilter.mode(
                        AppColors.abbey,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              notification.content,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                if (notification.profile?.fullName?.isNullOrEmpty == false)
                  Row(
                    children: [
                      Text(
                        notification.profile?.fullName ?? '',
                        style: const TextStyle(
                          color: AppColors.tundora,
                          fontSize: 12,
                        ),
                      ),
                      Container(
                        width: 4,
                        height: 4,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: const ShapeDecoration(
                          color: Color(0xFFA9DEC7),
                          shape: OvalBorder(),
                        ),
                      ),
                    ],
                  ),
                Text(
                  notification.created.getTimeAgo(),
                  style: const TextStyle(
                    color: AppColors.tundora,
                    fontSize: 12,
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
