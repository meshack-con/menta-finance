import '../../core/network/api_client.dart';
import 'models/dashboard_charts_model.dart';
import 'models/dashboard_summary_model.dart';

class DashboardService {
  final ApiClient _api;
  DashboardService(this._api);

  Future<DashboardSummaryModel> getSummary() async {
    final data = await _api.get('/api/dashboard/summary');
    return DashboardSummaryModel.fromJson(data as Map<String, dynamic>);
  }

  Future<DashboardChartsModel> getCharts() async {
    final data = await _api.get('/api/dashboard/charts');
    return DashboardChartsModel.fromJson(data as Map<String, dynamic>);
  }
}
