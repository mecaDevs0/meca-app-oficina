import 'package:flutter/material.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

class AppLoading extends StatelessWidget {
  const AppLoading({
    super.key,
    this.message = 'Carregando...',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SpinKitWave(
          itemCount: 4,
          itemBuilder: (_, int index) {
            return DecoratedBox(
              decoration: BoxDecoration(
                color: Get.theme.primaryColor,
              ),
            );
          },
          size: 20,
        ),
        const SizedBox(height: 10),
        Text(
          message,
          style: context.textTheme.bodyMedium,
        ),
      ],
    );
  }
}
