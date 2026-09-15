import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class ServiceRecord {
  final String id;
  final String name;
  final String description;

  const ServiceRecord({
    required this.id,
    required this.name,
    required this.description,
  });
}

/// Hifadhi ya Services - imeunganishwa moja kwa moja na Backend
/// (/api/services) - HAITUMII tena kumbukumbu ya muda (RAM) tu. Kila
/// 'add' inatuma ombi kwa Backend (Postgres) kabla ya kuongeza kwenye
/// orodha ya humu ndani (ili UI ionekane papo hapo).
class ServicesStore extends ChangeNotifier {
  final ApiClient _api;

  ServicesStore(this._api) {
    refresh();
  }

  List<ServiceRecord> services = [];
  bool isLoading = false;
  String? loadError;

  ServiceRecord _fromJson(Map<String, dynamic> j) => ServiceRecord(
        id: j['id'].toString(),
        name: j['name'] as String? ?? '',
        description: j['description'] as String? ?? '',
      );

  Future<void> refresh() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/services/') as List;
      services = data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      loadError = 'Imeshindikana kupakia Services kutoka kwenye mfumo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addService({required String name, required String description}) async {
    final data = await _api.post('/api/services/', body: {
      'name': name,
      if (description.trim().isNotEmpty) 'description': description,
    });
    services.insert(0, _fromJson(data as Map<String, dynamic>));
    notifyListeners();
  }
}
