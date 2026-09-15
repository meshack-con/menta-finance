import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../audit_service.dart';
import '../models/audit_log_model.dart';

class AuditController extends GetxController {
  final AuditService _service;
  AuditController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final logs = <AuditLogModel>[].obs;
  final searchText = ''.obs;
  final actionFilter = RxnString(); // null=Wote, CREATE/UPDATE/DELETE

  @override
  void onInit() {
    super.onInit();
    loadLogs();
  }

  Future<void> loadLogs() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      logs.assignAll(await _service.list(action: actionFilter.value));
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia audit trail.';
    } finally {
      isLoading.value = false;
    }
  }

  void setActionFilter(String? action) {
    actionFilter.value = action;
    loadLogs();
  }

  List<AuditLogModel> get filteredLogs {
    final q = searchText.value.trim().toLowerCase();
    if (q.isEmpty) return logs;
    return logs.where((l) {
      return (l.username ?? '').toLowerCase().contains(q) ||
          l.entityType.toLowerCase().contains(q) ||
          (l.description ?? '').toLowerCase().contains(q);
    }).toList();
  }
}
