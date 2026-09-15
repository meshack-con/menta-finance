import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../document_types_service.dart';
import '../models/document_type_model.dart';

class DocumentTypesController extends GetxController {
  final DocumentTypesService _service;
  DocumentTypesController(this._service);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final items = <DocumentTypeModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      items.assignAll(await _service.list());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia aina za nyaraka.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> save({int? id, required String name, String? description, bool isRequired = false, int sortOrder = 0}) async {
    isSaving.value = true;
    try {
      final item = DocumentTypeModel(name: name, description: description, isRequired: isRequired, sortOrder: sortOrder);
      if (id == null) {
        await _service.create(item);
      } else {
        await _service.update(id, item);
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await _service.delete(id);
      Get.snackbar('Imefanikiwa', 'Aina ya nyaraka imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
