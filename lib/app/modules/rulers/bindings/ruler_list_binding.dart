import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/ruler_list_controller.dart';
import '../ruler_service.dart';

class RulerListBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RulerService(Get.find<ApiClient>()));
    Get.lazyPut(() => RulerListController(Get.find<RulerService>()));
  }
}
