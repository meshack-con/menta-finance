import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../expenses_store.dart';

String _fmtExpenseMoney(num value) {
  final raw = value.toInt().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

class ExpensesView extends StatefulWidget {
  const ExpensesView({super.key});

  @override
  State<ExpensesView> createState() => _ExpensesViewState();
}

class _ExpensesViewState extends State<ExpensesView> {
  final _searchCtrl = TextEditingController();
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ExpensesStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final query = _searchCtrl.text.trim().toLowerCase();
        final rows = store.expenses
            .where((e) => e.name.toLowerCase().contains(query) || e.category.toLowerCase().contains(query))
            .toList();
        return AppShell(
          title: 'Expenses',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Expenses',
                      subtitle: 'Sajili na tazama matumizi (expenses) ya biashara yako.',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _RegisterExpenseDialog(store: store),
                    ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Sajili Expense'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: SizedBox(
                  width: 380,
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search, size: 20),
                      hintText: 'Tafuta kwa Jina au Aina',
                      isDense: true,
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Orodha ya Expenses', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          DataTableCard(
                            emptyIcon: Icons.receipt_long_outlined,
                            emptyTitle: 'Hakuna Expense',
                            emptySubtitle: 'Hakuna expense inayolingana na utafutaji wako.',
                            columns: const [
                              DataColumn(label: Text('Jina')),
                              DataColumn(label: Text('Aina')),
                              DataColumn(label: Text('Kiasi')),
                              DataColumn(label: Text('Tarehe ya Malipo')),
                            ],
                            rows: rows
                                .map(
                                  (e) => DataRow(
                                    cells: [
                                      DataCell(Text(e.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                      DataCell(Text(e.category)),
                                      DataCell(Text(_fmtExpenseMoney(e.amount))),
                                      DataCell(Text(_dateFmt.format(e.paidAt))),
                                    ],
                                  ),
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

class _RegisterExpenseDialog extends StatefulWidget {
  final ExpensesStore store;
  const _RegisterExpenseDialog({required this.store});

  @override
  State<_RegisterExpenseDialog> createState() => _RegisterExpenseDialogState();
}

class _RegisterExpenseDialogState extends State<_RegisterExpenseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _categoryCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  DateTime? _paidAt;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _categoryCtrl.dispose();
    _amountCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _paidAt ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _paidAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_paidAt == null) {
      Get.snackbar('Kosa', 'Chagua tarehe ya malipo.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await widget.store.addExpense(
        name: _nameCtrl.text.trim(),
        category: _categoryCtrl.text.trim(),
        amount: double.parse(_amountCtrl.text.trim()),
        paidAt: _paidAt!,
        description: _descriptionCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Get.snackbar('Kosa', 'Imeshindikana kusajili expense. Jaribu tena.', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  String? _requiredValidator(String? value) => value == null || value.trim().isEmpty ? 'Jaza sehemu hii' : null;

  String? _amountValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jaza kiasi';
    if (double.tryParse(value.trim()) == null) return 'Kiasi si namba sahihi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Expense'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(labelText: 'Jina la Expense (mfano: Mishahara)'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _categoryCtrl,
                  decoration: const InputDecoration(labelText: 'Aina (Category)'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Kiasi'),
                  validator: _amountValidator,
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: const InputDecoration(labelText: 'Tarehe ya Malipo', suffixIcon: Icon(Icons.calendar_today_outlined, size: 16)),
                    child: Text(_paidAt == null ? 'Chagua tarehe' : _dateFmt.format(_paidAt!)),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionCtrl,
                  decoration: const InputDecoration(labelText: 'Maelezo (hiari)'),
                  maxLines: 2,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ghairi')),
        ElevatedButton(onPressed: _submit, child: const Text('Sajili')),
      ],
    );
  }
}
