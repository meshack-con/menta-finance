import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/dashboard_controller.dart';
import '../dashboard_service.dart';

class DashboardBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DashboardService(Get.find<ApiClient>()));
    Get.lazyPut(() => DashboardController(Get.find<DashboardService>()));
  }
}
