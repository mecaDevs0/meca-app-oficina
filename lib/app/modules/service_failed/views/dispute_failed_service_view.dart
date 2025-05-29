import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../../../core/core.dart';
import '../controllers/service_failed_controller.dart';

class DisputeFailedServiceView extends StatefulWidget {
  const DisputeFailedServiceView({super.key});

  @override
  State<DisputeFailedServiceView> createState() =>
      _DisputeFailedServiceViewState();
}

class _DisputeFailedServiceViewState
    extends MegaState<DisputeFailedServiceView, ServiceFailedController> {
  final reasonController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const BaseAppBar(title: 'Contestar serviço reprovado'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Obx(
          () => Column(
            children: [
              SvgPicture.asset(
                AppImages.icContest,
              ),
              const SizedBox(height: 24),
              const Text(
                'Você está contestando uma reprovação',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.abbey,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Informe por gentileza os detalhes da sua contestação ao serviço reprovado',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.abbey,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Motivos',
                  style: TextStyle(
                    color: AppColors.boulder,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                maxLines: 4,
                controller: reasonController,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.all(16),
                  hintText: 'Descreva o motivo da reprovação',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                      color: AppColors.grayBorderColor,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                      color: AppColors.grayBorderColor,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                    borderSide: BorderSide(
                      color: AppColors.grayBorderColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Fotos',
                  style: TextStyle(
                    color: AppColors.boulder,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  MegaFilePicker.showModalChooser(
                    context,
                    onFilesSelected: controller.addImages,
                    cameraColor: AppColors.primaryColor,
                    galleryColor: AppColors.primaryColor,
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.asset(AppImages.icCamera),
                          const SizedBox(width: 8),
                          const Text(
                            'Incluir fotos',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (controller.selectedImages.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Imagens ${controller.selectedImages.length}/${controller.maxImages}',
                        style: const TextStyle(
                          color: AppColors.black,
                          fontSize: 16,
                        ),
                      ),
                      const Divider(),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: controller.selectedImages.length,
                        itemBuilder: (context, index) {
                          final file = controller.selectedImages[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(4),
                                    image: DecorationImage(
                                      image: FileImage(file),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    file.path.split('/').last,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () => controller.removeImage(file),
                                  child: const Icon(
                                    Icons.delete_outline,
                                    color: AppColors.apricot,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 24),
              MegaBaseButton(
                'Enviar contestação',
                textStyle: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                ),
                borderRadius: 4,
                onButtonPress: () async {
                  final isSuccess = await controller.disputeFailedService(
                    reasonController.text,
                  );

                  if (isSuccess && context.mounted) {
                    AppBottomSheet.showCompleteModal(
                      context,
                      icon: AppImages.icContestSuccess,
                      title: 'Informações enviadas!',
                      message:
                          'Em breve a equipe da Meca analisará a contestação'
                          ' e entrará em contato o mais breve possível.',
                      buttonText: 'Ver detalhes',
                      onButtonPress: () => Get.back<bool>(
                        closeOverlays: true,
                        result: true,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
