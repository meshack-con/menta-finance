import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class IncomeRecord {
  final String id;
  final String clientId;
  final String clientName;
  final String projectId;
  final String projectName;
  final double amount;
  final DateTime paidAt;
  final DateTime createdAt;

  const IncomeRecord({
    required this.id,
    required this.clientId,
    required this.clientName,
    required this.projectId,
    required this.projectName,
    required this.amount,
    required this.paidAt,
    required this.createdAt,
  });
}

/// Hifadhi ya Income - CHANZO RASMI cha Income kwenye mfumo huu.
/// Imeunganishwa moja kwa moja na Backend (/api/income) - HAITUMII
/// mockup data. Kila Project inaposajiliwa ikiwa na 'paid' > 0, Income
/// huingizwa Backend kiotomatiki; hapa pia tunaweza 'kusajili Income
/// mpya' kwa Project iliyopo tayari (mfano: mteja kalipa zaidi baadaye).
class IncomeStore extends ChangeNotifier {
  final ApiClient _api;

  IncomeStore(this._api) {
    refresh();
  }

  List<IncomeRecord> incomes = [];
  bool isLoading = false;
  String? loadError;

  IncomeRecord _fromJson(Map<String, dynamic> j) => IncomeRecord(
        id: j['id'].toString(),
        clientId: j['client_id'].toString(),
        clientName: j['client_name'] as String? ?? '-',
        projectId: j['project_id'].toString(),
        projectName: j['project_name'] as String? ?? '-',
        amount: double.parse(j['amount'].toString()),
        paidAt: DateTime.parse(j['paid_at'] as String),
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Future<void> refresh() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/income') as List;
      incomes = data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      loadError = 'Imeshindikana kupakia Income kutoka kwenye mfumo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  double get total => incomes.fold(0, (sum, i) => sum + i.amount);

  Future<void> addIncome({
    required String clientId,
    required String projectId,
    required double amount,
  }) async {
    final data = await _api.post('/api/income', body: {
      'client_id': int.parse(clientId),
      'project_id': int.parse(projectId),
      'amount': amount,
    });
    incomes.insert(0, _fromJson(data as Map<String, dynamic>));
    notifyListeners();
  }
}
