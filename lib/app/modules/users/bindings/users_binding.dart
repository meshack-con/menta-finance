import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/users_controller.dart';
import '../users_service.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => UsersService(Get.find<ApiClient>()));
    Get.lazyPut(() => UsersController(Get.find<UsersService>()));
  }
}
