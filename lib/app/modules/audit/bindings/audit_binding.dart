import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../audit_service.dart';
import '../controllers/audit_controller.dart';

class AuditBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => AuditService(Get.find<ApiClient>()));
    Get.lazyPut(() => AuditController(Get.find<AuditService>()));
  }
}
