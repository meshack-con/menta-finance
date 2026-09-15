import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/data/client_project_store.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';

class RulerListView extends StatefulWidget {
  const RulerListView({super.key});

  @override
  State<RulerListView> createState() => _RulerListViewState();
}

class _RulerListViewState extends State<RulerListView> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _openClientDetail(ClientRecord client) {
    Get.toNamed(AppRoutes.clientDetail, arguments: client.id);
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ClientProjectStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final query = _searchCtrl.text.trim().toLowerCase();
        final rows = store.clients
            .where((client) => client.name.toLowerCase().contains(query))
            .toList();
        return AppShell(
          title: 'Clients',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(
                    child: PageHeader(
                      title: 'Clients',
                      subtitle: 'Sajili na tazama taarifa za clients pamoja na projects zao.',
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _RegisterClientDialog(store: store),
                    ),
                    icon: const Icon(Icons.person_add_alt_1, size: 18),
                    label: const Text('Sajili Client'),
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
                      hintText: 'Tafuta Client kwa Jina',
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
                          const Text('Orodha ya Clients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 14),
                          DataTableCard(
                            emptyIcon: Icons.people_outline,
                            emptyTitle: 'Hakuna Client',
                            emptySubtitle: 'Hakuna client anayelingana na utafutaji wako.',
                            columns: const [
                              DataColumn(label: Text('Jina la Client')),
                              DataColumn(label: Text('Namba ya Simu')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Kitendo')),
                            ],
                            rows: rows
                                .map(
                                  (client) => DataRow(
                                    cells: [
                                      DataCell(
                                        SizedBox(
                                          width: 220,
                                          child: Text(
                                            client.name,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.w700),
                                          ),
                                        ),
                                      ),
                                      DataCell(Text(client.phone)),
                                      DataCell(Text(client.email.isEmpty ? '-' : client.email)),
                                      DataCell(
                                        OutlinedButton.icon(
                                          onPressed: () => _openClientDetail(client),
                                          icon: const Icon(Icons.visibility_outlined, size: 16),
                                          label: const Text('Tazama'),
                                        ),
                                      ),
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

class _RegisterClientDialog extends StatefulWidget {
  final ClientProjectStore store;
  const _RegisterClientDialog({required this.store});

  @override
  State<_RegisterClientDialog> createState() => _RegisterClientDialogState();
}

class _RegisterClientDialogState extends State<_RegisterClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    try {
      await widget.store.addClient(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Get.snackbar('Kosa', 'Imeshindikana kusajili client. Jaribu tena.', snackPosition: SnackPosition.BOTTOM);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Client'),
      content: SizedBox(
        width: 430,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Jina la Client'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Jaza jina la client'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Namba ya Simu ya Ofisi'),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Jaza namba ya simu'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email (hiari)'),
                validator: (value) => value != null &&
                        value.trim().isNotEmpty &&
                        !value.contains('@')
                    ? 'Ingiza email sahihi'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Ghairi'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Sajili')),
      ],
    );
  }
}

