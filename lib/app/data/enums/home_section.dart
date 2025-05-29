import '../../core/core.dart';

enum HomeSection {
  upcoming('Próximos'),
  history('Histórico');

  const HomeSection(this.description);
  final String description;

  String get icon {
    return switch (this) {
      HomeSection.upcoming => AppImages.icNext,
      HomeSection.history => AppImages.icHistory
    };
  }
}
