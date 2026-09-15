import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/forum_categories_controller.dart';
import '../forum_categories_service.dart';

class ForumCategoriesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => ForumCategoriesService(Get.find<ApiClient>()));
    Get.lazyPut(() => ForumCategoriesController(Get.find<ForumCategoriesService>()));
  }
}
