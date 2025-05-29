import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_features/mega_features.dart';

import '../../../core/core.dart';
import 'widgets/form_container.dart';
import 'widgets/success_container.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState
    extends MegaState<ForgotPasswordView, ForgotPasswordController> {
  bool _isSuccess = false;

  @override
  Widget build(BuildContext context) {
    SetSystemHelper.setSystemUIOverlayStyle(
      statusBarIconBrightness: Brightness.light,
      statusBarColor: Colors.white,
    );
    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SetSystemHelper.setSystemUIOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: AppColors.primaryColor,
          );
        }
      },
      child: Scaffold(
        body: Visibility(
          visible: !_isSuccess,
          replacement: const SuccessContainer(),
          child: FormContainer(
            onButtonPress: () async {
              final isSuccess = await controller.onSubmit(
                isBackScreen: false,
              );

              if (isSuccess) {
                setState(() {
                  _isSuccess = true;
                });
              }
            },
          ),
        ),
      ),
    );
  }
}
