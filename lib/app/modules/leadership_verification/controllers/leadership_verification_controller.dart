import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../leadership_verification_service.dart';
import '../models/pending_position_model.dart';

class LeadershipVerificationController extends GetxController {
  final LeadershipVerificationService _service;
  LeadershipVerificationController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final pending = <PendingPositionModel>[].obs;

  // ruler_id -> jina, leadership_id -> jina (kwa maonyesho)
  final rulerNames = <int, String>{}.obs;
  final leadershipNames = <int, String>{}.obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      pending.assignAll(await _service.listPending());

      // Vuta majina ya leadership zote (idadi ndogo, salama kuvuta zote)
      final leaderships = await _service.listLeaderships();
      leadershipNames.assignAll({for (final l in leaderships) l['id'] as int: l['name'] as String});

      // Vuta jina la kila ruler mwenye ombi (moja moja, orodha kawaida ni ndogo)
      for (final p in pending) {
        if (!rulerNames.containsKey(p.rulerId)) {
          try {
            final r = await _service.getRuler(p.rulerId);
            rulerNames[p.rulerId] = '${r['first_name'] ?? ''} ${r['last_name'] ?? ''}'.trim();
          } catch (_) {
            rulerNames[p.rulerId] = 'Ruler #${p.rulerId}';
          }
        }
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia maombi ya uongozi.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> verify(int id) async {
    try {
      await _service.verify(id);
      Get.snackbar('Imefanikiwa', 'Uongozi umethibitishwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> reject(int id) async {
    try {
      await _service.reject(id);
      Get.snackbar('Imefanikiwa', 'Ombi limekataliwa/kufutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
