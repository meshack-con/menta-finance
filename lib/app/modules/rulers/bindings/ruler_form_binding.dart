import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/ruler_form_controller.dart';
import '../ruler_service.dart';

class RulerFormBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => RulerService(Get.find<ApiClient>()));
    final int? rulerId = Get.arguments is int ? Get.arguments as int : null;
    Get.lazyPut(() => RulerFormController(Get.find<RulerService>(), rulerId: rulerId));
  }
}
