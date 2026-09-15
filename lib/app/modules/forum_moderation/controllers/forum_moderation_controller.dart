import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../forum_moderation_service.dart';
import '../models/forum_report_model.dart';

class ForumModerationController extends GetxController {
  final ForumModerationService _service;
  ForumModerationController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final reports = <ForumReportModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadReports();
  }

  Future<void> loadReports() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      reports.assignAll(await _service.listReports());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia ripoti.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> dismissReport(int id) async {
    try {
      await _service.deleteReport(id);
      Get.snackbar('Imefanikiwa', 'Ripoti imeondolewa.', snackPosition: SnackPosition.BOTTOM);
      loadReports();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> blockContent(ForumReportModel report) async {
    try {
      if (report.entityType == 'TOPIC') {
        await _service.blockTopic(report.entityId);
      } else if (report.entityType == 'OPPORTUNITY') {
        await _service.blockOpportunity(report.entityId);
      }
      Get.snackbar('Imefanikiwa', 'Kitu kimezuiwa (blocked).', snackPosition: SnackPosition.BOTTOM);
      await dismissReport(report.id);
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }
}
