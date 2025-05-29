import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../core.dart';

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onButtonPress});

  final void Function()? onButtonPress;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (onButtonPress != null) {
          onButtonPress!();
        } else {
          Get.back();
        }
      },
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Row(
        children: [
          SvgPicture.asset(
            AppImages.icBack,
            height: 12,
          ),
          const SizedBox(width: 8),
          const Text(
            'Voltar',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.abbey,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
