import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../models/stakeholder_model.dart';
import '../stakeholders_service.dart';

class StakeholdersController extends GetxController {
  final StakeholdersService _service;
  StakeholdersController(this._service);

  final isLoading = true.obs;
  final isSaving = false.obs;
  final errorMessage = RxnString();
  final items = <StakeholderModel>[].obs;
  final kindFilter = RxnString(); // null = Wote
  final searchText = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      items.assignAll(await _service.list(kind: kindFilter.value, q: searchText.value.isEmpty ? null : searchText.value));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia wadau.';
    } finally {
      isLoading.value = false;
    }
  }

  void setKindFilter(String? kind) {
    kindFilter.value = kind;
    loadAll();
  }

  Future<bool> save({
    int? id,
    required String name,
    required String kind,
    String? phoneNumber,
    String? emailAddress,
    String? address,
    String? contactPerson,
    String? notes,
  }) async {
    isSaving.value = true;
    try {
      final item = StakeholderModel(
        name: name, kind: kind, phoneNumber: phoneNumber, emailAddress: emailAddress,
        address: address, contactPerson: contactPerson, notes: notes,
      );
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
      Get.snackbar('Imefanikiwa', 'Mdau amefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
