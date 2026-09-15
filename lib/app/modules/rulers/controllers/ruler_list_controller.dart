import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../models/ruler_model.dart';
import '../ruler_service.dart';

class RulerListController extends GetxController {
  final RulerService _service;
  RulerListController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final rulers = <RulerModel>[].obs;

  final searchText = ''.obs;
  final roleFilter = Rxn<String>(); // null=Wote, 'leader', 'member'

  final pageSize = 20;
  final currentPage = 1.obs;
  final hasMore = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadRulers();
  }

  Future<void> loadRulers({bool resetPage = true}) async {
    if (resetPage) currentPage.value = 1;
    isLoading.value = true;
    errorMessage.value = null;
    try {
      final skip = (currentPage.value - 1) * pageSize;
      final result = await _service.list(
        skip: skip,
        limit: pageSize,
        q: searchText.value.isEmpty ? null : searchText.value,
        role: roleFilter.value,
      );
      rulers.assignAll(result);
      hasMore.value = result.length == pageSize;
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia orodha ya wanachama.';
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String value) {
    searchText.value = value;
    loadRulers();
  }

  void setRoleFilter(String? role) {
    roleFilter.value = role;
    loadRulers();
  }

  void nextPage() {
    if (!hasMore.value) return;
    currentPage.value++;
    loadRulers(resetPage: false);
  }

  void previousPage() {
    if (currentPage.value <= 1) return;
    currentPage.value--;
    loadRulers(resetPage: false);
  }

  Future<void> deleteRuler(int id) async {
    try {
      await _service.delete(id);
      Get.snackbar('Imefanikiwa', 'Mwanachama amefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadRulers(resetPage: false);
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  /// Inarudisha {membershipCode, defaultPassword} kama imefanikiwa, ili
  /// UI ionyeshe dialog ya "Akaunti Imeundwa" - null kama imeshindikana.
  Future<({String? membershipCode, String defaultPassword})?> generateLoginAccount(int rulerId) async {
    try {
      final updated = await _service.generateLoginAccount(rulerId);
      loadRulers(resetPage: false);
      return (membershipCode: updated.membershipCode, defaultPassword: updated.defaultPassword ?? '');
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return null;
    }
  }

  /// Admin anaweka password MAALUM kwa Member - inafanya kazi awe na
  /// akaunti tayari au la.
  Future<bool> resetRulerPassword(int rulerId, String newPassword) async {
    try {
      await _service.resetPassword(rulerId, newPassword);
      Get.snackbar('Imefanikiwa', 'Password ya mwanachama imebadilishwa.', snackPosition: SnackPosition.BOTTOM);
      loadRulers(resetPage: false);
      return true;
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
      return false;
    }
  }
}
