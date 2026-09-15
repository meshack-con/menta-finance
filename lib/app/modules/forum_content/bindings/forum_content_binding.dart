import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/forum_content_controller.dart';
import '../forum_content_service.dart';

class ForumContentBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ForumContentService(Get.find<ApiClient>()));
    Get.lazyPut(() => ForumContentController(Get.find<ForumContentService>()));
  }
}
