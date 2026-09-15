import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../login_history_service.dart';
import '../models/login_history_model.dart';

class LoginHistoryController extends GetxController {
  final LoginHistoryService _service;
  LoginHistoryController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final history = <LoginHistoryModel>[].obs;
  final searchText = ''.obs;

  List<LoginHistoryModel> get filteredHistory {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return history;
    return history.where((h) {
      return (h.username ?? '').toLowerCase().contains(q) ||
          (h.phoneNumber ?? '').toLowerCase().contains(q) ||
          (h.roles ?? '').toLowerCase().contains(q) ||
          (h.deviceUsed ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  void onInit() {
    super.onInit();
    loadHistory();
  }

  Future<void> loadHistory() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      history.assignAll(await _service.list());
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia historia ya login.';
    } finally {
      isLoading.value = false;
    }
  }
}
