import '../../core/network/api_client.dart';
import 'models/pending_position_model.dart';

class LeadershipVerificationService {
  final ApiClient _api;
  LeadershipVerificationService(this._api);

  Future<List<PendingPositionModel>> listPending() async {
    final data = await _api.get('/api/ruler-positions/pending', query: {'limit': 200});
    return (data as List).map((e) => PendingPositionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> verify(int id) => _api.put('/api/ruler-positions/$id/verify');
  Future<void> reject(int id) => _api.delete('/api/ruler-positions/$id');

  // Kupata majina ya kuonyesha (ruler/leadership) - tunatumia endpoints
  // zilizopo tayari (Admin token ina ruhusa).
  Future<Map<String, dynamic>> getRuler(int id) async {
    final data = await _api.get('/api/rulers/$id');
    return data as Map<String, dynamic>;
  }

  Future<List<dynamic>> listLeaderships() async {
    final data = await _api.get('/api/leaderships/', query: {'limit': 500});
    return data as List;
  }
}
