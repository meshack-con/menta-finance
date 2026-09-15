import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/forum_moderation_controller.dart';
import '../forum_moderation_service.dart';

class ForumModerationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ForumModerationService(Get.find<ApiClient>()));
    Get.lazyPut(() => ForumModerationController(Get.find<ForumModerationService>()));
  }
}
