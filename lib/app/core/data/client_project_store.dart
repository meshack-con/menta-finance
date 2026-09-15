import 'package:flutter/foundation.dart';

import '../network/api_client.dart';

class ClientRecord {
  final String id;
  final String name;
  final String phone;
  final String email;

  const ClientRecord({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
  });
}

class ProjectRecord {
  final String id;
  final String clientId;
  final String name;
  final String type;
  final DateTime registeredAt;
  final DateTime deadline;
  final double amount;
  final double paid;
  final DateTime createdAt;

  const ProjectRecord({
    required this.id,
    required this.clientId,
    required this.name,
    required this.type,
    required this.registeredAt,
    required this.deadline,
    required this.amount,
    required this.paid,
    required this.createdAt,
  });

  // Outstanding haitakiwi kuwa negative popote inapotumika - inaanza
  // na sifuri (0) na haiendi chini ya sifuri hata kama paid > amount.
  double get outstanding {
    final value = amount - paid;
    return value > 0 ? value : 0;
  }

  ProjectRecord copyWith({double? paid}) => ProjectRecord(
        id: id,
        clientId: clientId,
        name: name,
        type: type,
        registeredAt: registeredAt,
        deadline: deadline,
        amount: amount,
        paid: paid ?? this.paid,
        createdAt: createdAt,
      );
}

/// Hifadhi ya Clients/Projects - imeunganishwa moja kwa moja na Backend
/// (/api/clients, /api/projects). Data HAIPOTEI tena baada ya refresh
/// kwa sababu kila 'add' inatuma ombi kwa Backend (Postgres) kabla ya
/// kuongeza kwenye orodha ya humu ndani (ili UI ionekane papo hapo).
class ClientProjectStore extends ChangeNotifier {
  final ApiClient _api;

  ClientProjectStore(this._api) {
    refresh();
  }

  List<ClientRecord> clients = [];
  List<ProjectRecord> projects = [];
  bool isLoading = false;
  String? loadError;

  ClientRecord _clientFromJson(Map<String, dynamic> j) => ClientRecord(
        id: j['id'].toString(),
        name: j['name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        email: j['email'] as String? ?? '',
      );

  ProjectRecord _projectFromJson(Map<String, dynamic> j) => ProjectRecord(
        id: j['id'].toString(),
        clientId: j['client_id'].toString(),
        name: j['name'] as String? ?? '',
        type: j['project_type'] as String? ?? '',
        registeredAt: DateTime.parse(j['registered_at'] as String),
        deadline: DateTime.parse(j['deadline'] as String),
        amount: double.parse(j['amount'].toString()),
        paid: double.parse(j['paid'].toString()),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Future<void> refresh() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final clientsData = await _api.get('/api/clients') as List;
      final projectsData = await _api.get('/api/projects') as List;
      clients = clientsData.map((e) => _clientFromJson(e as Map<String, dynamic>)).toList();
      projects = projectsData.map((e) => _projectFromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      loadError = 'Imeshindikana kupakia Clients/Projects kutoka kwenye mfumo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addClient({required String name, required String phone, required String email}) async {
    final data = await _api.post('/api/clients', body: {
      'name': name,
      'phone': phone,
      if (email.trim().isNotEmpty) 'email': email,
    });
    clients.add(_clientFromJson(data as Map<String, dynamic>));
    notifyListeners();
  }

  Future<void> addProject({
    required String clientId,
    required String name,
    required String type,
    required DateTime registeredAt,
    required DateTime deadline,
    required double amount,
    required double paid,
  }) async {
    String isoDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final data = await _api.post('/api/projects', body: {
      'client_id': int.parse(clientId),
      'name': name,
      'project_type': type,
      'registered_at': isoDate(registeredAt),
      'deadline': isoDate(deadline),
      'amount': amount,
      'paid': paid,
    });
    projects.add(_projectFromJson(data as Map<String, dynamic>));
    notifyListeners();
  }

  List<ProjectRecord> projectsFor(String clientId) => projects.where((project) => project.clientId == clientId).toList();

  /// Inatumika mara tu Income mpya inaposajiliwa kwenye sehemu ya Income
  /// (angalia IncomeStore.addIncome) ili taarifa za Client/Project humu
  /// (ikiwemo column ya 'paid' kwenye Client Detail) ziongezeke papo hapo,
  /// bila kusubiri 'refresh' mpya kutoka Backend.
  void applyIncomePayment({required String projectId, required double amount}) {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index == -1) return;
    projects[index] = projects[index].copyWith(paid: projects[index].paid + amount);
    notifyListeners();
  }
}
