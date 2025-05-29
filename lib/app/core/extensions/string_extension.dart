import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

extension StringExtension on String? {
  bool get isUrl {
    if (this == null) {
      return false;
    }
    final startWithHttp = this!.startsWith('http://');
    final startWithHttps = this!.startsWith('https://');
    return startWithHttp || startWithHttps;
  }

  String get formattedPhone {
    if (this == null) {
      return '';
    }
    if (this!.length > 11) {
      return this!;
    }
    return UtilBrasilFields.obterTelefone(this!);
  }
}
