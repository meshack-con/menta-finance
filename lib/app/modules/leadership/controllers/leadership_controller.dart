import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../../lookup/models/lookup_item_model.dart';
import '../leadership_service.dart';
import '../models/leadership_model.dart';

class LeadershipController extends GetxController {
  final LeadershipService _service;
  LeadershipController(this._service);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final items = <LeadershipModel>[].obs;
  final titles = <LookupItemModel>[].obs;
  final searchText = ''.obs;

  List<LeadershipModel> get filteredItems {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      return item.name.toLowerCase().contains(q) ||
          (item.section ?? '').toLowerCase().contains(q) ||
          titleNameOf(item.titleId).toLowerCase().contains(q);
    }).toList();
  }

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
      titles.assignAll(await _service.listTitles());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia nafasi za uongozi.';
    } finally {
      isLoading.value = false;
    }
  }

  String titleNameOf(int titleId) {
    for (final t in titles) {
      if (t.id == titleId) return t.name;
    }
    return '-';
  }

  Future<bool> save({int? id, required String name, int? number, String? section, required int titleId}) async {
    isSaving.value = true;
    try {
      final item = LeadershipModel(name: name, number: number, section: section, titleId: titleId);
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
      Get.snackbar('Imefanikiwa', 'Nafasi imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
