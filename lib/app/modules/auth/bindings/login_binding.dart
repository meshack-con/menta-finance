import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/storage_service.dart';
import '../auth_service.dart';
import '../controllers/login_controller.dart';

class LoginBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuthService(Get.find<ApiClient>()));
    Get.lazyPut(() => LoginController(Get.find<AuthService>(), Get.find<StorageService>()));
  }
}
