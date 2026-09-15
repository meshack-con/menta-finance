import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/leadership_controller.dart';
import '../leadership_service.dart';

class LeadershipBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeadershipService(Get.find<ApiClient>()));
    Get.lazyPut(() => LeadershipController(Get.find<LeadershipService>()));
  }
}
