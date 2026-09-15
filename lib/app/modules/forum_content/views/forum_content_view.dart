import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../stakeholders/services_store.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';

String _fmtProjectMoney(num value) {
  final raw = value.toInt().toString();
  final buffer = StringBuffer();
  for (var i = 0; i < raw.length; i++) {
    if (i != 0 && (raw.length - i) % 3 == 0) buffer.write(',');
    buffer.write(raw[i]);
  }
  return 'TZS $buffer';
}

class ForumContentView extends StatefulWidget {
  const ForumContentView({super.key});

  @override
  State<ForumContentView> createState() => _ForumContentViewState();
}

class _ForumContentViewState extends State<ForumContentView> {
  final _nameCtrl = TextEditingController();
  final _typeCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime? _dateFilter;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _typeCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _hasActiveFilters =>
      _nameCtrl.text.isNotEmpty ||
      _typeCtrl.text.isNotEmpty ||
      _amountCtrl.text.isNotEmpty ||
      _dateFilter != null;

  List<ProjectRecord> _filtered(ClientProjectStore store) {
    final name = _nameCtrl.text.trim().toLowerCase();
    final type = _typeCtrl.text.trim().toLowerCase();
    final amount = _amountCtrl.text.trim().toLowerCase();
    return store.projects.where((project) {
      if (name.isNotEmpty && !project.name.toLowerCase().contains(name)) return false;
      if (type.isNotEmpty && !project.type.toLowerCase().contains(type)) return false;
      if (_dateFilter != null &&
          (project.registeredAt.year != _dateFilter!.year ||
              project.registeredAt.month != _dateFilter!.month ||
              project.registeredAt.day != _dateFilter!.day)) {
        return false;
      }
      return amount.isEmpty ||
          project.amount.toStringAsFixed(0).contains(amount) ||
          _fmtProjectMoney(project.amount).toLowerCase().contains(amount);
    }).toList();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateFilter ?? DateTime.now(),
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _dateFilter = picked);
  }

  void _clearFilters() {
    setState(() {
      _nameCtrl.clear();
      _typeCtrl.clear();
      _amountCtrl.clear();
      _dateFilter = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _filtered(store);
        return AppShell(
          title: 'Projects',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Projects',
                      subtitle: 'Sajili projects kwa client aliye kwenye mfumo na fuatilia malipo.',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: store.clients.isEmpty
                        ? null
                        : () => showDialog<void>(
                              context: context,
                              builder: (_) => _CreateProjectDialog(store: store),
                            ),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Sajili Project'),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SizedBox(width: 220, child: TextField(controller: _nameCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 20), hintText: 'Tafuta kwa Jina', isDense: true), onChanged: (_) => setState(() {}))),
                      SizedBox(width: 180, child: TextField(controller: _typeCtrl, decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined, size: 20), hintText: 'Tafuta kwa Aina', isDense: true), onChanged: (_) => setState(() {}))),
                      SizedBox(
                        width: 190,
                        child: InkWell(
                          onTap: _pickDate,
                          child: InputDecorator(
                            decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today_outlined, size: 18), isDense: true),
                            child: Text(_dateFilter == null ? 'Tafuta kwa Tarehe' : _dateFmt.format(_dateFilter!), style: TextStyle(color: _dateFilter == null ? AppColors.textSecondary : AppColors.textPrimary, fontSize: 14)),
                          ),
                        ),
                      ),
                      SizedBox(width: 180, child: TextField(controller: _amountCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixIcon: Icon(Icons.payments_outlined, size: 20), hintText: 'Tafuta kwa Kiasi', isDense: true), onChanged: (_) => setState(() {}))),
                      if (_hasActiveFilters) TextButton.icon(onPressed: _clearFilters, icon: const Icon(Icons.close, size: 16), label: const Text('Futa Vichujio')),
                    ],
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
                          const Text('Orodha ya Projects', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          DataTableCard(
                            emptyTitle: 'Hakuna Project',
                            emptySubtitle: 'Hakuna project inayolingana na utafutaji wako.',
                            columns: const [DataColumn(label: Text('Jina la Project')), DataColumn(label: Text('Client')), DataColumn(label: Text('Aina')), DataColumn(label: Text('Tarehe')), DataColumn(label: Text('Deadline')), DataColumn(label: Text('Kiasi')), DataColumn(label: Text('Paid'))],
                            rows: rows.map((project) {
                              final client = store.clients.firstWhereOrNull((item) => item.id == project.clientId);
                              return DataRow(cells: [
                                DataCell(Text(project.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                                DataCell(Text(client?.name ?? '-')),
                                DataCell(Text(project.type)),
                                DataCell(Text(_dateFmt.format(project.registeredAt))),
                                DataCell(Text(_dateFmt.format(project.deadline))),
                                DataCell(Text(_fmtProjectMoney(project.amount))),
                                DataCell(Text(_fmtProjectMoney(project.paid))),
                              ]);
                            }).toList(),
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

class _CreateProjectDialog extends StatefulWidget {
  final ClientProjectStore store;
  const _CreateProjectDialog({required this.store});

  @override
  State<_CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<_CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _paidCtrl = TextEditingController(text: '0');
  String? _clientId;
  String? _selectedType;
  DateTime? _registeredAt;
  DateTime? _deadline;
  final _dateFmt = DateFormat('dd/MM/yyyy');

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _paidCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool deadline}) async {
    final picked = await showDatePicker(context: context, initialDate: deadline ? _deadline ?? DateTime.now() : _registeredAt ?? DateTime.now(), firstDate: DateTime(2015), lastDate: DateTime(2100));
    if (picked != null) setState(() => deadline ? _deadline = picked : _registeredAt = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clientId == null || _registeredAt == null || _deadline == null) {
      Get.snackbar('Kosa', 'Chagua client, tarehe ya kuingizwa na deadline.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (_selectedType == null) {
      Get.snackbar('Kosa', 'Chagua Aina ya Project.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final amount = double.parse(_amountCtrl.text.trim());
    final paid = double.parse(_paidCtrl.text.trim());
    if (paid > amount) {
      Get.snackbar('Kosa', 'Paid haiwezi kuzidi bei ya project.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    try {
      await widget.store.addProject(clientId: _clientId!, name: _nameCtrl.text.trim(), type: _selectedType!, registeredAt: _registeredAt!, deadline: _deadline!, amount: amount, paid: paid);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Get.snackbar('Kosa', 'Imeshindikana kusajili project. Jaribu tena.', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  String? _moneyValidator(String? value) {
    if (value == null || value.trim().isEmpty) return 'Jaza kiasi';
    if (double.tryParse(value.trim()) == null) return 'Kiasi si namba sahihi';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Project'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              DropdownButtonFormField<String>(initialValue: _clientId, decoration: const InputDecoration(labelText: 'Jina la Client'), items: widget.store.clients.map((client) => DropdownMenuItem(value: client.id, child: Text(client.name))).toList(), onChanged: (value) => setState(() => _clientId = value), validator: (value) => value == null ? 'Chagua client' : null),
              const SizedBox(height: 12),
              TextFormField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Project'), validator: (value) => value == null || value.trim().isEmpty ? 'Jaza jina la project' : null),
              const SizedBox(height: 12),
              Builder(builder: (context) {
                final servicesStore = Get.find<ServicesStore>();
                return AnimatedBuilder(
                  animation: servicesStore,
                  builder: (context, _) {
                    final serviceNames = servicesStore.services.map((s) => s.name).toSet().toList();
                    // Chagua "Aina" kutoka kwenye Services zilizosajiliwa (angalia
                    // ukurasa wa Services) - siyo tena maandishi ya kujiandikia.
                    return DropdownButtonFormField<String>(
                      initialValue: serviceNames.contains(_selectedType) ? _selectedType : null,
                      decoration: InputDecoration(
                        labelText: 'Aina',
                        helperText: serviceNames.isEmpty ? 'Hakuna Service bado - sajili Service kwanza.' : null,
                      ),
                      items: serviceNames.map((name) => DropdownMenuItem(value: name, child: Text(name))).toList(),
                      onChanged: serviceNames.isEmpty ? null : (value) => setState(() => _selectedType = value),
                      validator: (value) => value == null ? 'Chagua aina' : null,
                    );
                  },
                );
              }),
              const SizedBox(height: 12),
              _DateField(label: 'Tarehe Kazi Ilipotolewa', value: _registeredAt, dateFmt: _dateFmt, onTap: () => _pickDate(deadline: false)),
              const SizedBox(height: 12),
              _DateField(label: 'Deadline', value: _deadline, dateFmt: _dateFmt, onTap: () => _pickDate(deadline: true)),
              const SizedBox(height: 12),
              TextFormField(controller: _amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Bei ya Project'), validator: _moneyValidator),
              const SizedBox(height: 12),
              TextFormField(controller: _paidCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Paid'), validator: _moneyValidator),
            ]),
          ),
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ghairi')), ElevatedButton(onPressed: _submit, child: const Text('Sajili Project'))],
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final DateTime? value;
  final DateFormat dateFmt;
  final VoidCallback onTap;

  const _DateField({required this.label, required this.value, required this.dateFmt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(onTap: onTap, child: InputDecorator(decoration: InputDecoration(labelText: label, suffixIcon: const Icon(Icons.calendar_today_outlined, size: 16)), child: Text(value == null ? 'Chagua tarehe' : dateFmt.format(value!))));
  }
}
