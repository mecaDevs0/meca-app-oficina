import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/edit_profile_controller.dart';

class CompanyForm extends StatefulWidget {
  const CompanyForm({super.key});

  @override
  State<CompanyForm> createState() => _CompanyFormState();
}

class _CompanyFormState extends MegaState<CompanyForm, EditProfileController> {
  final _formKey = GlobalKey<FormState>();
  final companyNameController = TextEditingController();
  final openingHoursController = TextEditingController();
  final cnpjController = TextEditingController();

  @override
  void initState() {
    companyNameController.text = controller.workshop.companyName ?? '';
    openingHoursController.text = controller.workshop.openingHours ?? '';
    cnpjController.text =
        UtilBrasilFields.obterCnpj(controller.workshop.cnpj ?? '');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Logo do estabelecimento',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(width: 4),
              Text(
                '(opcional)',
                style: TextStyle(
                  color: AppColors.hintTextColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: Obx(
              () => MegaPhotoContainer(
                profilePhoto: controller.workshop.photo,
                photo: controller.fileLogo,
                onPhotoChanged: (file) {
                  controller.fileLogo = File(file.path);
                },
                typeModal: TypeModal.bottomSheet,
                buttonColor: AppColors.primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Requisitos',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          const AppRequirementItem(
            title: 'Formato',
            subtitle: '.jpg, .jpeg, .png',
          ),
          const AppRequirementItem(
            title: 'Tamanho máximo do arquivo',
            subtitle: 'de 1mb',
          ),
          const AppRequirementItem(
            title: 'Tamanho da imagem',
            subtitle: '1000px x 1000px',
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: companyNameController,
            label: 'Nome da empresa',
            hintText: 'Digite o nome da empresa',
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            isRequired: true,
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: openingHoursController,
            label: 'Horário de funcionamento',
            hintText: 'Selecione o horário que a empresa abre',
            isRequired: true,
            onTap: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return AppBodyTimerModal(
                    onConfirm: (value) {
                      openingHoursController.text = value;
                    },
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: cnpjController,
            onTap: kDebugMode
                ? () {
                    if (kDebugMode) {
                      cnpjController.text = UtilBrasilFields.gerarCNPJ();
                    }
                  }
                : null,
            label: 'CNPJ',
            hintText: 'Digite o CNPJ da empresa',
            keyboardType: TextInputType.number,
            validator: Validatorless.multiple(
              [
                Validatorless.required('CNPJ é obrigatório'),
                Validatorless.cnpj('CNPJ inválido'),
              ],
            ),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CnpjInputFormatter(),
            ],
          ),
          const SizedBox(height: 16),
          const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Cartão MEI',
                style: TextStyle(
                  color: AppColors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(width: 2),
              Text(
                '(opcional)',
                style: TextStyle(
                  color: AppColors.hintTextColor,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Obx(() {
            if (controller.fileMeiCard != null) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: ShapeDecoration(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 1, color: Color(0xFFDBDBDB)),
                    borderRadius: BorderRadius.circular(4),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SvgPicture.asset(
                      AppImages.icCard,
                      width: 16,
                      height: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Cartão MEI',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.abbey,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: () {
                        controller.fileMeiCard = null;
                      },
                      child: SvgPicture.asset(
                        AppImages.icClose,
                        width: 16,
                        height: 16,
                      ),
                    ),
                  ],
                ),
              );
            }
            return GestureDetector(
              onTap: () {
                MegaFilePicker.showModalChooser(
                  context,
                  canSelectFile: true,
                  onFileSelected: (file) {
                    if (file == null) {
                      return;
                    }
                    controller.fileMeiCard = File(file.path);
                  },
                  cameraColor: AppColors.primaryColor,
                  galleryColor: AppColors.primaryColor,
                  fileColor: AppColors.primaryColor,
                );
              },
              child: Container(
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                child: CustomPaint(
                  painter: AppDashedBorderPainter(
                    color: AppColors.abbey,
                    borderRadius: 4,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: const Text(
                      'Faça upload do cartão MEI',
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          Obx(
            () => MegaBaseButton(
              'Salvar alterações',
              isLoading: controller.isLoading,
              onButtonPress: () {
                if (_formKey.currentState?.validate() == false) {
                  return;
                }
                final workshop = controller.workshop.copyWith(
                  companyName: companyNameController.text,
                  openingHours: openingHoursController.text,
                  cnpj: UtilBrasilFields.obterCnpj(cnpjController.text),
                );
                controller.onEditWorkshop(workshop);
              },
              textStyle: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
              borderRadius: 4,
            ),
          ),
        ],
      ),
    );
  }
}
