import '../../core/app_images.dart';

enum StepRegister {
  establishment('Empresa', AppImages.icEstablishment),
  address('Endereço', AppImages.icPin),
  responsible('Responsável', AppImages.icPerson);

  const StepRegister(this.description, this.icon);
  final String description;
  final String icon;
}
