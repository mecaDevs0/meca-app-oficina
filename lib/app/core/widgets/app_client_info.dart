import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../core.dart';

class AppClientInfo extends StatelessWidget {
  const AppClientInfo({
    super.key,
    required this.name,
    this.email,
    this.phone,
  });

  final String name;
  final String? email;
  final String? phone;

  Future<void> openWhatsApp(String phone) async {
    final url = 'https://wa.me/$phone';

    if (!await launchUrl(Uri.parse(url))) {
      MegaSnackbar.showErroSnackBar(
        'Não foi possível abrir o WhatsApp',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: const TextStyle(
            color: AppColors.abbey,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          spacing: 8,
          children: [
            SvgPicture.asset(
              AppImages.icEmail,
            ),
            Text(
              email ?? '',
              style: const TextStyle(
                color: AppColors.abbey,
              ),
            ),
          ],
        ),
        if (phone.isNullOrEmpty == false)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => openWhatsApp(phone!),
                child: Row(
                  spacing: 8,
                  children: [
                    SvgPicture.asset(
                      AppImages.icWhatsapp,
                    ),
                    Text(
                      phone.formattedPhone,
                      style: const TextStyle(
                        color: AppColors.abbey,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        const Divider(),
      ],
    );
  }
}
