import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/login_history_controller.dart';
import '../login_history_service.dart';

class LoginHistoryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LoginHistoryService(Get.find<ApiClient>()));
    Get.lazyPut(() => LoginHistoryController(Get.find<LoginHistoryService>()));
  }
}
