import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../forum_categories_service.dart';
import '../models/forum_category_model.dart';

class ForumCategoriesController extends GetxController {
  final ForumCategoriesService _service;
  ForumCategoriesController(this._service);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final categories = <ForumCategoryModel>[].obs;
  final kindFilter = RxnString(); // null=Wote, OPPORTUNITY, DISCUSSION

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      categories.assignAll(await _service.list(kind: kindFilter.value));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia categories.';
    } finally {
      isLoading.value = false;
    }
  }

  void setKindFilter(String? kind) {
    kindFilter.value = kind;
    loadAll();
  }

  Future<bool> save({int? id, required String name, String? icon, required String kind, int sortOrder = 0}) async {
    isSaving.value = true;
    try {
      final item = ForumCategoryModel(name: name, icon: icon, kind: kind, sortOrder: sortOrder);
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
      Get.snackbar('Imefanikiwa', 'Category imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
