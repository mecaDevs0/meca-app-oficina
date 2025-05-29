import 'package:mega_commons/shared/data/mega_data_cache.dart';
import 'package:mega_commons_dependencies/mega_commons_dependencies.dart';

import '../data.dart';

class BaseHive {
  BaseHive._();

  static Future<void> initHive() async {
    await MegaDataCache.initialize('meca');

    Hive.registerAdapter(WorkshopModelAdapter());

    await MegaDataCache.openBox<WorkshopModel>();
  }
}
