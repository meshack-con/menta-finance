import '../../core/network/api_client.dart';
import 'models/admin_position_model.dart';
import 'models/lookup_option.dart';
import 'models/ruler_attachment_model.dart';
import 'models/ruler_model.dart';

class RulerService {
  final ApiClient _api;
  RulerService(this._api);

  Future<List<RulerModel>> list({int skip = 0, int limit = 100, String? q, String? role}) async {
    final data = await _api.get('/api/rulers/', query: {
      'skip': skip,
      'limit': limit,
      if (q != null && q.isNotEmpty) 'q': q,
      if (role != null) 'role': role,
    });
    return (data as List).map((e) => RulerModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<RulerModel> get(int id) async {
    final data = await _api.get('/api/rulers/$id');
    return RulerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RulerModel> create(RulerModel ruler, {bool overrideCcm = false}) async {
    final data = await _api.post('/api/rulers/', body: ruler.toJson(), query: {'override_ccm': overrideCcm});
    return RulerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<RulerModel> update(int id, RulerModel ruler) async {
    final data = await _api.put('/api/rulers/$id', body: ruler.toJson());
    return RulerModel.fromJson(data as Map<String, dynamic>);
  }

  Future<void> delete(int id) => _api.delete('/api/rulers/$id');

  /// Admin anabofya "Tengeneza Akaunti" - inarudisha default_password mpya.
  Future<RulerModel> generateLoginAccount(int id) async {
    final data = await _api.put('/api/rulers/$id/generate-login');
    return RulerModel.fromJson(data as Map<String, dynamic>);
  }

  /// Admin anaweka PASSWORD MAALUM (siyo default) - inafanya kazi hata
  /// kama Member tayari ana akaunti.
  Future<void> resetPassword(int id, String newPassword) async {
    await _api.put('/api/rulers/$id/reset-password', body: {'new_password': newPassword});
  }

  // ---------- Uongozi (kwa hatua ya 6 ya fomu - hiari) ----------

  Future<List<LookupOption>> listLeaderships() async {
    final data = await _api.get('/api/leaderships/', query: {'limit': 500});
    return (data as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LookupOption>> listRegions() async {
    final data = await _api.get('/api/regions/', query: {'limit': 500});
    return (data as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LookupOption>> listBranches() async {
    final data = await _api.get('/api/branches/', query: {'limit': 500});
    return (data as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>, parentKey: 'region_id')).toList();
  }

  Future<List<LookupOption>> listOccupations() async {
    final data = await _api.get('/api/occupations/');
    return (data as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<LookupOption>> listOccupationTypes() async {
    final data = await _api.get('/api/occupation-types/');
    return (data as List).map((e) => LookupOption.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Admin akiongeza nafasi hii - inathibitishwa (is_verified=True) MOJA
  /// KWA MOJA na backend (angalia app/ruler_position/router.py POST).
  Future<void> addPosition({
    required int rulerId,
    required int leadershipId,
    required int regionId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dateFmt = (DateTime d) => '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    await _api.post('/api/ruler-positions/', body: {
      'ruler_id': rulerId,
      'leadership_id': leadershipId,
      'region_id': regionId,
      'start_date': startDate == null ? null : dateFmt(startDate),
      'end_date': endDate == null ? null : dateFmt(endDate),
    });
  }

  // ---------- Picha na Nyaraka (preview/download) ----------

  /// Inarudisha bytes za picha, au null kama hana picha (404).
  Future<List<int>?> getPhotoBytes(int rulerId) async {
    try {
      return await _api.getBytes('/api/rulers/$rulerId/photo');
    } catch (_) {
      return null;
    }
  }

  Future<List<RulerAttachmentModel>> listAttachments(int rulerId) async {
    final data = await _api.get('/api/ruler-attachments/ruler/$rulerId');
    return (data as List).map((e) => RulerAttachmentModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<int>> previewAttachmentBytes(int attachmentId) {
    return _api.getBytes('/api/ruler-attachments/$attachmentId/preview');
  }

  Future<List<int>> downloadAttachmentBytes(int attachmentId) {
    return _api.getBytes('/api/ruler-attachments/$attachmentId/download');
  }

  // ---------- Historia ya Uongozi ----------

  Future<List<AdminPositionModel>> listPositionsForRuler(int rulerId) async {
    final data = await _api.get('/api/ruler-positions/ruler/$rulerId');
    return (data as List).map((e) => AdminPositionModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  // ---------- CV ----------

  Future<Map<String, dynamic>> getCv(int rulerId) async {
    final data = await _api.get('/api/rulers/$rulerId/cv');
    return data as Map<String, dynamic>;
  }

  Future<List<int>> getCvPdfBytes(int rulerId) {
    return _api.getBytes('/api/rulers/$rulerId/cv/pdf');
  }
}
