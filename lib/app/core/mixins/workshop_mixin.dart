import 'package:get/get.dart';

import '../../data/data.dart';

mixin WorkshopMixin on GetxController {
  final WorkshopModel _workshop = WorkshopModel.fromCache();

  WorkshopModel get loggedUser {
    if (_workshop == null) {
      throw Exception('User not logged in');
    }
    return _workshop;
  }

  String get email => _workshop.email ?? '';
}
