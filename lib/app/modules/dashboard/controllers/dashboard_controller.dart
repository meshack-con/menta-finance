import 'package:get/get.dart';

import '../../../core/network/api_exception.dart';
import '../dashboard_service.dart';
import '../models/dashboard_charts_model.dart';
import '../models/dashboard_summary_model.dart';

class DashboardController extends GetxController {
  final DashboardService _service;
  DashboardController(this._service);

  final isLoading = true.obs;
  final errorMessage = RxnString();
  final Rxn<DashboardSummaryModel> summary = Rxn<DashboardSummaryModel>();

  final isLoadingCharts = true.obs;
  final Rxn<DashboardChartsModel> charts = Rxn<DashboardChartsModel>();

  @override
  void onInit() {
    super.onInit();
    loadSummary();
    loadCharts();
  }

  Future<void> loadSummary() async {
    isLoading.value = true;
    errorMessage.value = null;
    try {
      summary.value = await _service.getSummary();
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } catch (e) {
      errorMessage.value = 'Imeshindikana kupakia takwimu.';
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadCharts() async {
    isLoadingCharts.value = true;
    try {
      charts.value = await _service.getCharts();
    } catch (_) {
      // si hatari kubwa - StatCards za msingi bado zinaonekana bila charts
    } finally {
      isLoadingCharts.value = false;
    }
  }
}
