import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../forum_content_service.dart';
import '../models/admin_opportunity_model.dart';
import '../models/admin_topic_model.dart';

class ForumContentController extends GetxController {
  final ForumContentService _service;
  ForumContentController(this._service);

  final tabIndex = 0.obs; // 0 = Mada, 1 = Fursa
  final isLoading = true.obs;
  final errorMessage = RxnString();
  final searchText = ''.obs;

  final topics = <AdminTopicModel>[].obs;
  final opportunities = <AdminOpportunityModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    loadAll();
  }

  void switchTab(int index) {
    tabIndex.value = index;
    loadAll();
  }

  Future<void> loadAll() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      if (tabIndex.value == 0) {
        topics.assignAll(await _service.listTopics(q: searchText.value.isEmpty ? null : searchText.value));
      } else {
        opportunities.assignAll(await _service.listOpportunities(q: searchText.value.isEmpty ? null : searchText.value));
      }
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleTopicBlock(AdminTopicModel t) async {
    try {
      if (t.isBlocked) {
        await _service.unblockTopic(t.id);
      } else {
        await _service.blockTopic(t.id);
      }
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteTopic(int id) async {
    try {
      await _service.deleteTopic(id);
      Get.snackbar('Imefanikiwa', 'Mada imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> toggleOpportunityBlock(AdminOpportunityModel o) async {
    try {
      if (o.isBlocked) {
        await _service.unblockOpportunity(o.id);
      } else {
        await _service.blockOpportunity(o.id);
      }
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> deleteOpportunity(int id) async {
    try {
      await _service.deleteOpportunity(id);
      Get.snackbar('Imefanikiwa', 'Fursa imefutwa.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> approveOpportunity(int id) async {
    try {
      await _service.approveOpportunity(id);
      Get.snackbar('Imefanikiwa', 'Fursa imethibitishwa - sasa inaonekana kwa umma.', snackPosition: SnackPosition.BOTTOM);
      loadAll();
    } on ApiException catch (e) {
      Get.snackbar('Hitilafu', e.message, snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<Map<String, dynamic>?> getNotificationStats(int opportunityId) async {
    try {
      return await _service.getNotificationStats(opportunityId);
    } catch (_) {
      return null;
    }
  }

  int get pendingCount => opportunities.where((o) => !o.isApproved && !o.isBlocked).length;

  List<AdminTopicModel> get topRatedTopics {
    final rated = topics.where((t) => t.ratingCount > 0).toList();
    rated.sort((a, b) => b.averageRating.compareTo(a.averageRating));
    return rated.take(5).toList();
  }
}
