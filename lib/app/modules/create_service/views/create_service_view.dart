import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../../../data/data.dart';
import '../controllers/create_service_controller.dart';

class CreateServiceView extends StatefulWidget {
  const CreateServiceView({super.key});

  @override
  State<CreateServiceView> createState() => _CreateServiceViewState();
}

class _CreateServiceViewState
    extends MegaState<CreateServiceView, CreateServiceController> {
  final _formKey = GlobalKey<FormState>();
  final _antecedenceKey = GlobalKey();
  final serviceNameController = TextEditingController();
  final estimatedTimeController = TextEditingController();
  final antecedenceController = TextEditingController();
  final descriptionController = TextEditingController();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    ever(controller.serviceDetail, (service) {
      if (service == null) {
        return;
      }
      serviceNameController.text = service.service?.name ?? '';
      estimatedTimeController.text = service.estimatedTime.toString();
      antecedenceController.text = service.minTimeScheduling.toString();
      descriptionController.text = service.description ?? '';
      controller.selectedImage = service.photo;
      controller.isFastService = service.quickService ?? false;
    });
    super.initState();
  }

  void toggleInfoModal() {
    if (_overlayEntry == null) {
      _showInfoModal();
    } else {
      _hideInfoModal();
    }
  }

  double? formatDouble(String value) {
    try {
      return double.parse(value.replaceAll(',', '.'));
    } on Exception catch (e) {
      log('Error parsing double: $e');
    }
    return null;
  }

  void _showInfoModal() {
    final renderBox =
        _antecedenceKey.currentContext!.findRenderObject()! as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: position.dx,
        top: position.dy + 20,
        width: size.width,
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size.width,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    const Text(
                      'Antecedência mínima para o serviço',
                      style: TextStyle(
                        color: AppColors.abbey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _hideInfoModal,
                      child: const Icon(
                        Icons.close,
                        color: AppColors.abbey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Este campo define a antecedência mínima para o agendamento'
                  ' do serviço, ou seja, o tempo mínimo necessário entre a'
                  ' solicitação e o atendimento.',
                  style: TextStyle(
                    color: AppColors.abbey,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    setState(() {});
  }

  void _hideInfoModal() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    setState(() {});
  }

  Future<File?> cropImage(String sourcePath) async {
    File? photo;
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: sourcePath,
      aspectRatio: const CropAspectRatio(ratioX: 2.88, ratioY: 1),
      compressQuality: 80,
      uiSettings: [
        AndroidUiSettings(
          toolbarColor: Colors.black,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Editar Imagem',
        ),
      ],
    );
    if (croppedFile != null) {
      photo = File(croppedFile.path);
    }
    return photo;
  }

  Future<void> _validActionService(ServiceModel service) async {
    final isEdit = controller.serviceDetail.value != null;
    final replaceMessage = isEdit
        ? 'Serviço editado com sucesso'
        : 'Serviço cadastrado com sucesso';

    final result = isEdit
        ? await controller.onEditService(service)
        : await controller.onCreateService(service);

    if (result.$1) {
      Get.back(result: true);
      MegaSnackbar.showSuccessSnackBar(
        result.$2 ?? replaceMessage,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Cadastrar serviço'),
      body: Stack(
        children: [
          Obx(
            () {
              return Skeletonizer(
                enabled: controller.isLoadingService,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Imagem de capa',
                          style: TextStyle(
                            color: AppColors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Essa imagem será a capa do serviços',
                          style: TextStyle(
                            color: AppColors.hintTextColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(height: 16),
                        GestureDetector(
                          onTap: () {
                            MegaFilePicker.showModalChooser(
                              context,
                              onFileSelected: (file) async {
                                if (file == null) {
                                  return;
                                }
                                final croppedImage = await cropImage(file.path);
                                controller.selectedImage = croppedImage?.path;
                              },
                              cameraColor: AppColors.primaryColor,
                              galleryColor: AppColors.primaryColor,
                            );
                          },
                          child: Obx(() {
                            if (controller.selectedImage?.isUrl == true) {
                              return MegaCachedNetworkImage(
                                imageUrl: controller.selectedImage,
                                width: double.infinity,
                                height: 120,
                                radius: 4,
                                fit: BoxFit.cover,
                              );
                            }
                            if (controller.selectedImage?.isFile == true) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: Image.file(
                                  File(controller.selectedImage!),
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                ),
                              );
                            }
                            return Container(
                              width: double.infinity,
                              height: 120,
                              margin: const EdgeInsets.symmetric(horizontal: 2),
                              child: CustomPaint(
                                painter: AppDashedBorderPainter(
                                  color: AppColors.abbey,
                                  borderRadius: 4,
                                ),
                                child: const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.add,
                                        color: AppColors.primaryColor,
                                        size: 32,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ).unite,
                        const SizedBox(height: 16),
                        AppDropDown<DefaultServiceModel>(
                          label: 'Nome do serviço',
                          title: 'Selecione o serviço',
                          hintText: 'Digite o nome do serviço',
                          controller: serviceNameController,
                          onChanged: (service) {
                            serviceNameController.text = service.name;
                            controller.selectedService = service;
                          },
                          listDropDownItem: controller.defaultServices
                              .map(
                                (service) => MegaItemWidget(
                                  itemLabel: service.name,
                                  value: service,
                                ),
                              )
                              .toList(),
                        ).unite,
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: estimatedTimeController,
                          label: 'Tempo estimado(em horas)',
                          hintText: 'Digite o tempo estimado',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          isRequired: true,
                        ).unite,
                        const SizedBox(height: 16),
                        Container(
                          key: _antecedenceKey,
                          child: AppTextField(
                            controller: antecedenceController,
                            label: 'Antecedência mínima para o agendamento',
                            hintText: 'Digite a antecedência',
                            labelIcon: AppImages.icInfo,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            onTapInfo: () => toggleInfoModal(),
                            isRequired: true,
                          ),
                        ).unite,
                        const SizedBox(height: 16),
                        AppTextField(
                          controller: descriptionController,
                          label: 'Descrição',
                          hintText: 'Digite a descrição',
                          isMultiLine: true,
                          isRequired: true,
                        ).unite,
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text(
                              'Serviço rápido',
                              style: TextStyle(
                                color: Color(0xFF2D2D2D),
                              ),
                            ).unite,
                            const Spacer(),
                            Obx(
                              () => AppSwitch(
                                value: controller.isFastService,
                                onChanged: controller.toggleFastService,
                              ),
                            ).shade,
                          ],
                        ).moveUp(
                          begin: 40,
                        ),
                        const SizedBox(height: 16),
                        MegaBaseButton(
                          'Finalizar cadastro',
                          onButtonPress: () async {
                            if (_formKey.currentState?.validate() == false) {
                              return;
                            }
                            if (controller.selectedImage == null) {
                              MegaSnackbar.showErroSnackBar(
                                'Selecione uma imagem para o serviço',
                              );
                            }
                            final service = ServiceModel(
                              service: controller.selectedService,
                              estimatedTime:
                                  formatDouble(estimatedTimeController.text),
                              minTimeScheduling:
                                  formatDouble(antecedenceController.text),
                              description: descriptionController.text,
                              quickService: controller.isFastService,
                            );
                            FocusScope.of(context).unfocus();
                            await _validActionService(service);
                          },
                          borderRadius: 4,
                          isLoading: controller.isLoading,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ).moveUp().shade,
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          if (_overlayEntry != null)
            Container(
              color: Colors.black.withValues(alpha: .5),
            ),
        ],
      ),
    );
  }
}
