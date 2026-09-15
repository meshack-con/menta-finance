class ChartPointModel {
  final String label;
  final int value;
  ChartPointModel({required this.label, required this.value});

  factory ChartPointModel.fromJson(Map<String, dynamic> j) =>
      ChartPointModel(label: j['label'] as String, value: j['value'] as int);
}

/// Muamala mmoja wa "Recent Transactions" - INCOME (imeingizwa wakati wa
/// kusajili Project) au EXPENSE (imeingizwa kwenye sehemu ya Expenses).
class TransactionPointModel {
  final DateTime date;
  final String type; // 'INCOME' au 'EXPENSE'
  final String name;
  final int amount;

  TransactionPointModel({
    required this.date,
    required this.type,
    required this.name,
    required this.amount,
  });

  bool get isIncome => type == 'INCOME';

  factory TransactionPointModel.fromJson(Map<String, dynamic> j) => TransactionPointModel(
        date: DateTime.parse(j['date'] as String),
        type: j['type'] as String,
        name: j['name'] as String,
        amount: j['amount'] as int,
      );
}

class DashboardChartsModel {
  final List<TransactionPointModel> recentTransactions;
  final List<ChartPointModel> leaderVsMember;
  final List<ChartPointModel> membersByRegion;
  final List<ChartPointModel> registrationsByMonth;

  DashboardChartsModel({
    required this.recentTransactions,
    required this.leaderVsMember,
    required this.membersByRegion,
    required this.registrationsByMonth,
  });

  factory DashboardChartsModel.fromJson(Map<String, dynamic> j) {
    List<ChartPointModel> parse(String key) =>
        (j[key] as List).map((e) => ChartPointModel.fromJson(e as Map<String, dynamic>)).toList();
    return DashboardChartsModel(
      recentTransactions: (j['recent_transactions'] as List)
          .map((e) => TransactionPointModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      leaderVsMember: parse('leader_vs_member'),
      membersByRegion: parse('members_by_region'),
      registrationsByMonth: parse('registrations_by_month'),
    );
  }
}
