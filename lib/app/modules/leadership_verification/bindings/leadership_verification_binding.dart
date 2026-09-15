import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/leadership_verification_controller.dart';
import '../leadership_verification_service.dart';

class LeadershipVerificationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => LeadershipVerificationService(Get.find<ApiClient>()));
    Get.lazyPut(() => LeadershipVerificationController(Get.find<LeadershipVerificationService>()));
  }
}
