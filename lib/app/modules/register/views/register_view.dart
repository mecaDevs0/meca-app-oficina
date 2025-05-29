import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/register_controller.dart';
import 'address_form.dart';
import 'establishment_form.dart';
import 'responsible_form.dart';
import 'widgets/stepper_widget.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({super.key});

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends MegaState<RegisterView, RegisterController> {
  final establishmentFormKey = GlobalKey<FormState>();
  final addressFormKey = GlobalKey<FormState>();
  final responsibleFormKey = GlobalKey<FormState>();
  final companyNameController = TextEditingController();
  final openingHoursController = TextEditingController();
  final cnpjController = TextEditingController();
  final responsibleNameController = TextEditingController();
  final responsibleEmailController = TextEditingController();
  final responsiblePhoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  String get _makeTitle => 'Crie sua conta';
  String get _makeSubtitle => 'Preencha os campos abaixo para criar sua conta';
  String get _labelButton {
    return switch (controller.stepRegister) {
      StepRegister.establishment => 'Próximo',
      StepRegister.address => 'Próximo',
      StepRegister.responsible => 'Finalizar'
    };
  }

  bool get _validateEstablishmentForm {
    final currentStep = controller.stepRegister;
    if (currentStep != StepRegister.establishment) {
      return true;
    }
    final isValid = establishmentFormKey.currentState?.validate() ?? false;
    return isValid;
  }

  bool get _hasLogo {
    final currentStep = controller.stepRegister;
    if (currentStep != StepRegister.establishment) {
      return true;
    }
    final hasLogo = controller.logoFile != null;
    return hasLogo;
  }

  bool get _hasMeiCard {
    final currentStep = controller.stepRegister;
    if (currentStep != StepRegister.establishment) {
      return true;
    }
    final hasMeiCard = controller.cardMeiFile != null;
    return hasMeiCard;
  }

  bool get _validateAddressForm {
    final currentStep = controller.stepRegister;
    if (currentStep != StepRegister.address) {
      return true;
    }
    final isValid = addressFormKey.currentState?.validate() ?? false;
    return isValid;
  }

  bool get _validateResponsibleForm {
    final currentStep = controller.stepRegister;
    if (currentStep != StepRegister.responsible) {
      return true;
    }
    final isValid = responsibleFormKey.currentState?.validate() ?? false;
    return isValid;
  }

  Future<void> _validRegister() async {
    if (_validateEstablishmentForm == false) {
      return;
    }

    if (_hasLogo == false) {
      MegaSnackbar.showErroSnackBar(
        'É necessário adicionar a logo',
      );
      return;
    }

    if (_hasMeiCard == false) {
      MegaSnackbar.showErroSnackBar(
        'É necessário adicionar o cartão MEI',
      );
      return;
    }

    if (_validateAddressForm == false) {
      return;
    }
    if (_validateResponsibleForm == false) {
      return;
    }

    if (controller.stepRegister == StepRegister.establishment) {
      final cnpj = UtilBrasilFields.removeCaracteres(cnpjController.text);
      final workshop = controller.workshop.copyWith(
        companyName: companyNameController.text,
        openingHours: openingHoursController.text,
        cnpj: cnpj,
      );
      controller.workshop = workshop;
      log(controller.workshop.toJson().toString());
      controller.nextStep();
      return;
    }

    if (controller.stepRegister == StepRegister.address) {
      controller.populateAddress();
      controller.nextStep();
      return;
    }
    if (!controller.isPolicyTermChecked) {
      MegaSnackbar.showErroSnackBar(
        'Você deve aceitar os termos e condições',
      );
      return;
    }

    if (controller.stepRegister == StepRegister.responsible) {
      final phone = UtilBrasilFields.removeCaracteres(
        responsiblePhoneController.text,
      );
      final workshop = controller.workshop.copyWith(
        fullName: responsibleNameController.text,
        email: responsibleEmailController.text,
        phone: phone,
        password: passwordController.text,
      );
      final result = await controller.onRegisterWorkshop(workshop);
      if (!result) {
        return;
      }
      if (mounted) {
        Get.back();
        AppBottomSheet.showModalInfoSend(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    SetSystemHelper.setSystemUIOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.white,
    );

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) {
          SetSystemHelper.setSystemUIOverlayStyle(
            statusBarIconBrightness: Brightness.light,
            statusBarColor: AppColors.primaryColor,
          );
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: context.height * 0.07),
              AppBackButton(
                onButtonPress: () {
                  if (controller.stepRegister == StepRegister.establishment) {
                    Get.back();
                  } else {
                    controller.previousStep();
                  }
                },
              ),
              const SizedBox(height: 32),
              Text(
                _makeTitle,
                style: const TextStyle(
                  color: AppColors.abbey,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _makeSubtitle,
                style: const TextStyle(
                  color: AppColors.abbey,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              const StepperWidget(),
              const SizedBox(height: 32),
              Obx(
                () => switch (controller.stepRegister) {
                  StepRegister.establishment => EstablishmentForm(
                      formKey: establishmentFormKey,
                      companyNameController: companyNameController,
                      openingHoursController: openingHoursController,
                      cnpjController: cnpjController,
                    ),
                  StepRegister.address => AddressForm(formKey: addressFormKey),
                  StepRegister.responsible => ResponsibleForm(
                      formKey: responsibleFormKey,
                      responsibleNameController: responsibleNameController,
                      responsibleEmailController: responsibleEmailController,
                      responsiblePhoneController: responsiblePhoneController,
                      passwordController: passwordController,
                      confirmPasswordController: confirmPasswordController,
                    ),
                },
              ),
              const SizedBox(height: 32),
              Obx(
                () => MegaBaseButton(
                  _labelButton,
                  textStyle: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                  onButtonPress: _validRegister,
                  isLoading: controller.isLoading,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle.dark.copyWith(
        statusBarColor: AppColors.primaryColor,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    super.dispose();
  }
}
