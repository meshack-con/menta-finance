import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../income_store.dart';

String _fmtIncomeMoney(num value) {
  final raw = value.toInt().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

/// Ukurasa wa "Income" - CHANZO RASMI ni Backend (/api/income), SIYO
/// mockup data. Kitufe "Sajili Income" (juu kulia) kinamwezesha mtumiaji
/// kuchagua Client, kuchagua Project ya Client huyo, kisha kuingiza
/// kiasi (Income) kipya.
class IncomeView extends StatefulWidget {
  const IncomeView({super.key});

  @override
  State<IncomeView> createState() => _IncomeViewState();
}

class _IncomeViewState extends State<IncomeView> {
  final _searchCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final incomeStore = Get.find<IncomeStore>();
    final clientProjectStore = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: incomeStore,
      builder: (context, _) {
        final query = _searchCtrl.text.trim().toLowerCase();
        final rows = incomeStore.incomes
            .where((i) =>
                i.clientName.toLowerCase().contains(query) || i.projectName.toLowerCase().contains(query))
            .toList();
        return AppShell(
          title: 'Income',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Income',
                      subtitle: 'Income halisi ya mfumo - inatoka kwenye malipo ya Projects za Clients.',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: clientProjectStore.clients.isEmpty
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => _RegisterIncomeDialog(
                                incomeStore: incomeStore,
                                clientProjectStore: clientProjectStore,
                              ),
                            ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Sajili Income'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                width: 260,
                height: 84,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primaryGreen.withOpacity(0.18)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(color: AppColors.primaryGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(13)),
                      alignment: Alignment.center,
                      child: const Icon(Icons.trending_up, color: AppColors.primaryGreen),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Jumla ya Income', style: TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(height: 3),
                          Text(_fmtIncomeMoney(incomeStore.total), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 340,
                child: TextField(
                  controller: _searchCtrl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search, size: 20),
                    hintText: 'Tafuta kwa Client au Project',
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: incomeStore.isLoading && incomeStore.incomes.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Card(
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (incomeStore.loadError != null) ...[
                                  Text(incomeStore.loadError!, style: const TextStyle(color: AppColors.danger)),
                                  const SizedBox(height: 10),
                                  ElevatedButton(onPressed: incomeStore.refresh, child: const Text('Jaribu tena')),
                                  const SizedBox(height: 14),
                                ],
                                const Text('Orodha ya Income', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                const SizedBox(height: 14),
                                DataTableCard(
                                  emptyIcon: Icons.trending_up,
                                  emptyTitle: 'Hakuna Income bado',
                                  emptySubtitle: 'Sajili Income ya kwanza kwa kutumia kitufe hapo juu.',
                                  columns: const [
                                    DataColumn(label: Text('Client')),
                                    DataColumn(label: Text('Project')),
                                    DataColumn(label: Text('Kiasi')),
                                    DataColumn(label: Text('Tarehe')),
                                  ],
                                  rows: rows
                                      .map(
                                        (i) => DataRow(cells: [
                                          DataCell(Text(i.clientName, style: const TextStyle(fontWeight: FontWeight.w600))),
                                          DataCell(Text(i.projectName)),
                                          DataCell(Text(_fmtIncomeMoney(i.amount), style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700))),
                                          DataCell(Text(_dateFmt.format(i.paidAt))),
                                        ]),
                                      )
                                      .toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RegisterIncomeDialog extends StatefulWidget {
  final IncomeStore incomeStore;
  final ClientProjectStore clientProjectStore;
  const _RegisterIncomeDialog({required this.incomeStore, required this.clientProjectStore});

  @override
  State<_RegisterIncomeDialog> createState() => _RegisterIncomeDialogState();
}

class _RegisterIncomeDialogState extends State<_RegisterIncomeDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountCtrl = TextEditingController();
  String? _clientId;
  String? _projectId;
  bool _isSaving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  List<ProjectRecord> get _projectsForClient =>
      _clientId == null ? const [] : widget.clientProjectStore.projectsFor(_clientId!);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null || _projectId == null) {
      Get.snackbar('Kosa', 'Chagua Client na Project.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final amount = double.parse(_amountCtrl.text.trim());
      await widget.incomeStore.addIncome(
        clientId: _clientId!,
        projectId: _projectId!,
        amount: amount,
      );
      // Sasisha 'paid' ya Project/Client hii pekee (sehemu ya Client Detail)
      // papo hapo, bila kuathiri Client/Project nyingine yoyote.
      widget.clientProjectStore.applyIncomePayment(projectId: _projectId!, amount: amount);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Get.snackbar('Kosa', 'Imeshindikana kusajili income. Jaribu tena.', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jaza kiasi';
    if (double.tryParse(value.trim()) == null) return 'Kiasi si namba sahihi';
    if (double.parse(value.trim()) <= 0) return 'Kiasi lazima kiwe zaidi ya sifuri';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Income'),
      content: SizedBox(
        width: 440,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _clientId,
                  decoration: const InputDecoration(labelText: 'Jina la Client'),
                  items: widget.clientProjectStore.clients
                      .map((client) => DropdownMenuItem(value: client.id, child: Text(client.name)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _clientId = value;
                    _projectId = null;
                  }),
                  validator: (value) => value == null ? 'Chagua client' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _projectId,
                  decoration: InputDecoration(
                    labelText: 'Jina la Project',
                    helperText: _clientId != null && _projectsForClient.isEmpty ? 'Client huyu hana Project bado.' : null,
                  ),
                  items: _projectsForClient
                      .map((project) => DropdownMenuItem(value: project.id, child: Text(project.name)))
                      .toList(),
                  onChanged: _clientId == null ? null : (value) => setState(() => _projectId = value),
                  validator: (value) => value == null ? 'Chagua project' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kiasi (Income)'),
                  validator: _amountValidator,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ghairi')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sajili Income'),
        ),
      ],
    );
  }
}
