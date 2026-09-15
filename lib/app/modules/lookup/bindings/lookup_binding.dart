import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/lookup_controller.dart';
import '../lookup_config.dart';
import '../lookup_service.dart';

class LookupBinding extends Bindings {
  final LookupConfig config;
  LookupBinding(this.config);

  @override
  void dependencies() {
    Get.lazyPut<LookupService>(() => LookupService(Get.find<ApiClient>(), config.endpoint), tag: config.endpoint);
    Get.lazyPut<LookupController>(
      () => LookupController(Get.find<LookupService>(tag: config.endpoint), config),
      tag: config.endpoint,
    );
  }
}
