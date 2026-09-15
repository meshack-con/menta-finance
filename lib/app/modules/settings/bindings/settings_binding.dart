import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../../users/users_service.dart';
import '../controllers/settings_controller.dart';

class SettingsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UsersService(Get.find<ApiClient>()));
    Get.lazyPut(() => SettingsController(Get.find<UsersService>(), Get.find<StorageService>()));
  }
}
