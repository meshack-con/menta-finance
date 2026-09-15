import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../services_store.dart';

class ServicesView extends StatefulWidget {
  const ServicesView({super.key});

  @override
  State<ServicesView> createState() => _ServicesViewState();
}

class _ServicesViewState extends State<ServicesView> {
  Future<void> _showRegisterDialog(ServicesStore store) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _RegisterServiceDialog(store: store),
    );
  }

  void _showDescription(ServiceRecord service) {
    showDialog<void>(
      context: context,
      builder:
          (dialogContext) => AlertDialog(
            title: Text(service.name),
            content: Text(
              service.description,
              style: const TextStyle(height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Funga'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = Get.find<ServicesStore>();
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return AppShell(
          title: 'Services',
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 560;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flex(
                    direction: compact ? Axis.vertical : Axis.horizontal,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Services',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Orodha ya services zinazopatikana kwenye mfumo.',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (compact) const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () => _showRegisterDialog(store),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Sajili Service'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: store.isLoading && store.services.isEmpty
                        ? const Center(child: CircularProgressIndicator())
                        : SingleChildScrollView(
                            child: Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (store.loadError != null) ...[
                                      Text(store.loadError!, style: const TextStyle(color: AppColors.danger)),
                                      const SizedBox(height: 10),
                                      ElevatedButton(onPressed: store.refresh, child: const Text('Jaribu tena')),
                                      const SizedBox(height: 14),
                                    ],
                                    const Text('Orodha ya Services', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                                    const SizedBox(height: 14),
                                    _buildServicesTable(store),
                                  ],
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildServicesTable(ServicesStore store) {
    final rows =
        store.services.isEmpty
            ? [
              const DataRow(
                cells: [
                  DataCell(
                    Text(
                      'Hakuna service bado',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                  DataCell(
                    Text(
                      'Bonyeza "Sajili Service" kuongeza service ya kwanza.',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ]
            : store.services.map((service) {
              return DataRow(
                onSelectChanged: (_) => _showDescription(service),
                cells: [
                  DataCell(
                    Text(
                      service.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(
                    SizedBox(
                      width: 520,
                      child: Text(
                        service.description,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              );
            }).toList();

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder:
            (context, constraints) => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(minWidth: constraints.maxWidth),
                child: DataTable(
                  columnSpacing: 28,
                  headingRowColor: WidgetStateProperty.all(
                    AppColors.tableHeaderBg,
                  ),
                  headingTextStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 13,
                  ),
                  dataTextStyle: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                  ),
                  dataRowMinHeight: 52,
                  dataRowMaxHeight: 60,
                  horizontalMargin: 20,
                  columns: const [
                    DataColumn(label: Text('Jina la Service')),
                    DataColumn(label: Text('Maelezo Mafupi')),
                  ],
                  rows: rows,
                ),
              ),
            ),
      ),
    );
  }
}

class _RegisterServiceDialog extends StatefulWidget {
  final ServicesStore store;
  const _RegisterServiceDialog({required this.store});

  @override
  State<_RegisterServiceDialog> createState() => _RegisterServiceDialogState();
}

class _RegisterServiceDialogState extends State<_RegisterServiceDialog> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await widget.store.addService(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        Get.snackbar('Kosa', 'Imeshindikana kusajili service. Jaribu tena.', snackPosition: SnackPosition.BOTTOM);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Sajili Service'),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Jina la service'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Weka jina la service.' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Maelezo mafupi kuhusu service'),
                validator: (value) => value == null || value.trim().isEmpty ? 'Weka maelezo ya service.' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Ghairi')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          child: _isSaving
              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Sajili'),
        ),
      ],
    );
  }
}
