import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../lookup_config.dart';
import '../lookup_service.dart';
import '../models/lookup_item_model.dart';

class LookupController extends GetxController {
  final LookupService service;
  final LookupConfig config;

  LookupController(this.service, this.config);

  LookupService? _parentService;

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final items = <LookupItemModel>[].obs;
  final parentOptions = <LookupItemModel>[].obs;
  final searchText = ''.obs;

  /// Orodha iliyochujwa na search (jina la kitu chenyewe AU jina la mzazi wake).
  List<LookupItemModel> get filteredItems {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return items;
    return items.where((item) {
      if (item.name.toLowerCase().contains(q)) return true;
      if (config.parentKey != null && parentNameOf(item.parentId).toLowerCase().contains(q)) return true;
      return false;
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    if (config.parentConfig != null) {
      _parentService = LookupService(Get.find<ApiClient>(), config.parentConfig!.endpoint);
    }
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      items.assignAll(await service.list(parentKey: config.parentKey));
      if (_parentService != null) {
        parentOptions.assignAll(await _parentService!.list(parentKey: config.parentConfig!.parentKey));
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia orodha.';
    } finally {
      isLoading.value = false;
    }
  }

  String parentNameOf(int? parentId) {
    if (parentId == null) return '-';
    for (final p in parentOptions) {
      if (p.id == parentId) return p.name;
    }
    return '-';
  }

  Future<bool> save({int? id, required String name, int? parentId}) async {
    isSaving.value = true;
    try {
      final item = LookupItemModel(name: name, parentId: parentId);
      if (id == null) {
        await service.create(item, parentKey: config.parentKey);
      } else {
        await service.update(id, item, parentKey: config.parentKey);
      }
      await loadAll();
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kuhifadhi.', snackPosition: SnackPosition.BOTTOM);
      return false;
    } finally {
      isSaving.value = false;
    }
  }

  Future<void> delete(int id) async {
    try {
      await service.delete(id);
      Get.snackbar('Imefanikiwa', 'Kipengele kimefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
