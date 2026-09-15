import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../core/data/client_project_store.dart';
import '../../core/network/api_client.dart';
import '../expenses/expenses_store.dart';
import '../income/income_store.dart';
import '../stakeholders/services_store.dart';

/// Hifadhi ya Ripoti (Reports) - CHANZO ni Backend (/api/reports/overview),
/// ambayo yenyewe inasoma moja kwa moja kutoka kwenye jedwali halisi za
/// Clients/Projects/Income/Expenses/Services (siyo mockup).
///
/// "Real-time": Store hii inajisajili kusikiliza (addListener) IncomeStore,
/// ExpensesStore, ClientProjectStore na ServicesStore - kila mara mmoja
/// wapo anapobadilika (mfano: mtu kasajili Income/Expense/Project/Client/
/// Service mpya popote kwenye app), Report inajipakia upya (refresh) PAPO
/// HAPO bila kusubiri mtu abofye chochote. Kwa mabadiliko yanayofanywa na
/// mtumiaji MWINGINE (kwenye kifaa/tab tofauti), kuna 'polling' ya kila
/// sekunde 20 wakati ukurasa wa Reports upo wazi (angalia startPolling /
/// stopPolling - vinaitwa na ReportsView kwenye initState/dispose).
class ReportsStore extends ChangeNotifier {
  final ApiClient _api;
  final IncomeStore incomeStore;
  final ExpensesStore expensesStore;
  final ClientProjectStore clientProjectStore;
  final ServicesStore servicesStore;

  ReportsStore(
    this._api, {
    required this.incomeStore,
    required this.expensesStore,
    required this.clientProjectStore,
    required this.servicesStore,
  }) {
    incomeStore.addListener(_onSourceChanged);
    expensesStore.addListener(_onSourceChanged);
    clientProjectStore.addListener(_onSourceChanged);
    servicesStore.addListener(_onSourceChanged);
    refresh();
  }

  Timer? _pollTimer;
  bool isLoading = false;
  String? loadError;
  Map<String, dynamic>? data;

  void _onSourceChanged() => refresh();

  /// Anza 'polling' ya mara kwa mara - itwe wakati ukurasa wa Reports
  /// unafunguliwa (initState), ili kupata mabadiliko yanayofanywa kwenye
  /// vifaa/session nyingine bila mtu huyu kubofya "Jaribu tena" mwenyewe.
  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 20), (_) => refresh());
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  Future<void> refresh() async {
    isLoading = data == null; // spinner kamili mara ya kwanza tu
    notifyListeners();
    try {
      final result = await _api.get('/api/reports/overview');
      data = result as Map<String, dynamic>;
      loadError = null;
    } catch (e) {
      loadError = 'Imeshindikana kupakia Report kutoka kwenye mfumo.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    incomeStore.removeListener(_onSourceChanged);
    expensesStore.removeListener(_onSourceChanged);
    clientProjectStore.removeListener(_onSourceChanged);
    servicesStore.removeListener(_onSourceChanged);
    _pollTimer?.cancel();
    super.dispose();
  }
}
