import '../../core/core.dart';

enum UserMenuOption {
  edit('Editar dados', 'Atualize seus dados.'),
  service('Serviços', 'Gerencie os serviços do estabelecimento.'),
  dataBank('Dados bancários', 'Atualize dados bancários.'),
  changePassword('Alterar senha', 'Modifique sua senha.'),
  helpCenter('Central de ajuda', 'Suporte e dúvidas.'),
  logout('Sair', 'Encerrar sessão.');

  const UserMenuOption(this.title, this.subtitle);
  final String title;
  final String subtitle;

  String get icon {
    return switch (this) {
      UserMenuOption.edit => AppImages.icEdit,
      UserMenuOption.service => AppImages.icService,
      UserMenuOption.dataBank => AppImages.icDataBank,
      UserMenuOption.changePassword => AppImages.icLock,
      UserMenuOption.helpCenter => AppImages.icHelp,
      UserMenuOption.logout => AppImages.icExit,
    };
  }
}
