import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';

class ExpenseRecord {
  final String id;
  final String name;
  final String category;
  final double amount;
  final DateTime paidAt;
  final String? description;
  final DateTime createdAt;

  const ExpenseRecord({
    required this.id,
    required this.name,
    required this.category,
    required this.amount,
    required this.paidAt,
    required this.description,
    required this.createdAt,
  });
}

/// Hifadhi ya Expenses - imeunganishwa moja kwa moja na Backend
/// (/api/expenses). Data haihifadhiwi kwenye kumbukumbu ya muda tu -
/// kila 'add' inatuma ombi kwa Backend (Postgres) kwanza.
class ExpensesStore extends ChangeNotifier {
  final ApiClient _api;

  ExpensesStore(this._api) {
    refresh();
  }

  List<ExpenseRecord> expenses = [];
  bool isLoading = false;
  String? loadError;

  ExpenseRecord _fromJson(Map<String, dynamic> j) => ExpenseRecord(
        id: j['id'].toString(),
        name: j['name'] as String? ?? '',
        category: j['category'] as String? ?? '',
        amount: double.parse(j['amount'].toString()),
        paidAt: DateTime.parse(j['paid_at'] as String),
        description: j['description'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );

  Future<void> refresh() async {
    isLoading = true;
    loadError = null;
    notifyListeners();
    try {
      final data = await _api.get('/api/expenses') as List;
      expenses = data.map((e) => _fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      loadError = 'Imeshindikana kupakia Expenses kutoka kwenye mfumo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addExpense({
    required String name,
    required String category,
    required double amount,
    required DateTime paidAt,
    String? description,
  }) async {
    String isoDate(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    final data = await _api.post('/api/expenses', body: {
      'name': name,
      'category': category,
      'amount': amount,
      'paid_at': isoDate(paidAt),
      if (description != null && description.trim().isNotEmpty) 'description': description,
    });
    expenses.insert(0, _fromJson(data as Map<String, dynamic>));
    notifyListeners();
  }
}
