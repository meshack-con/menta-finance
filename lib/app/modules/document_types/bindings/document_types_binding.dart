import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../controllers/document_types_controller.dart';
import '../document_types_service.dart';

class DocumentTypesBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => DocumentTypesService(Get.find<ApiClient>()));
    Get.lazyPut(() => DocumentTypesController(Get.find<DocumentTypesService>()));
  }
}
