import 'package:flutter/material.dart';
import 'package:mega_commons/mega_commons.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';
import 'package:mega_features/app/firebase/firebase_config.dart';

import 'app/application_binding.dart';
import 'app/data/cache/base_hive.dart';
import 'app/routes/app_pages.dart';
import 'app/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';

  await Future.wait([
    FirebaseConfig.initialize(),
    BaseHive.initHive(),
  ]);
  await MegaOneSignalConfig.configure(
    appKey: 'b2d9eb72-de92-4a59-ab91-30484d64f403',
  );

  final token = AuthToken.fromCache();

  final String initialRoute = token == null ? AppPages.initial : Routes.core;

  initializeDateFormatting('pt_BR', null);

  AliceAdapter.instance(Get.key);


  runApp(
    GetMaterialApp(
      navigatorKey: Get.key,
      title: 'Meca Oficina',
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      initialBinding: ApplicationBinding(),
      theme: AppTheme.theme,
      builder: (_, child) {
        return MegaBannerEnv(
          navigationKey: Get.key,
          location: BannerLocation.topStart,
          child: child ?? const SizedBox.shrink(),
        );
      },
    ),
  );
}
