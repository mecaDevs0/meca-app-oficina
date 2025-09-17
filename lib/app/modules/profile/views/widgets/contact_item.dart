import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import '../../../../core/core.dart';

class ContactItem extends StatelessWidget {
  const ContactItem({
    super.key,
    required this.icon,
    required this.label,
    this.iconColor,
    this.textColor,
  });

  final String icon;
  final String label;
  final Color? iconColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          icon,
          width: 16,
          height: 16,
          colorFilter: iconColor != null 
              ? ColorFilter.mode(iconColor!, BlendMode.srcIn)
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: textColor ?? AppColors.silver,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
