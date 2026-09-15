import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/lookup_controller.dart';
import '../lookup_config.dart';
import '../models/lookup_item_model.dart';

class LookupListView extends StatelessWidget {
  final LookupConfig config;
  const LookupListView({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<LookupController>(tag: config.endpoint);

    return AppShell(
      title: config.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: PageHeader(
                  title: config.title,
                  subtitle: 'Simamia orodha ya ${config.addLabel.toLowerCase()} kwenye mfumo.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context, controller),
                icon: const Icon(Icons.add, size: 18),
                label: Text('Ongeza ${config.addLabel}'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Tafuta kwa jina...',
                isDense: true,
              ),
              onChanged: (v) => controller.searchText.value = v,
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }
              if (controller.errorMessage.value != null) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                    ],
                  ),
                );
              }
              final list = controller.filteredItems;
              if (list.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inbox_outlined, size: 42, color: Colors.grey.shade400),
                      const SizedBox(height: 10),
                      Text(
                        controller.searchText.value.isEmpty
                            ? 'Hakuna "${config.title}" bado.'
                            : 'Hakuna matokeo ya "${controller.searchText.value}".',
                        style: const TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                );
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: [
                    const DataColumn(label: Text('Jina')),
                    if (config.parentKey != null) DataColumn(label: Text(config.parentLabel ?? 'Mzazi')),
                    const DataColumn(label: Text('Vitendo')),
                  ],
                  rows: list.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      if (config.parentKey != null) DataCell(Text(controller.parentNameOf(item.parentId))),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          onPressed: () => _showFormDialog(context, controller, existing: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, controller, item),
                        ),
                      ])),
                    ]);
                  }).toList(),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, LookupController controller, LookupItemModel item) {
    Get.dialog(
      AlertDialog(
        title: Text('Futa ${config.addLabel}'),
        content: Text('Una uhakika unataka kufuta "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.delete(item.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, LookupController controller, {LookupItemModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final selectedParent = RxnInt(existing?.parentId);

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza ${config.addLabel}' : 'Hariri ${config.addLabel}'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: InputDecoration(labelText: 'Jina la ${config.addLabel}'),
              ),
              if (config.parentKey != null) ...[
                const SizedBox(height: 14),
                Obx(
                  () => DropdownButtonFormField<int>(
                    value: selectedParent.value,
                    decoration: InputDecoration(labelText: 'Chagua ${config.parentLabel}'),
                    items: controller.parentOptions
                        .map((p) => DropdownMenuItem(value: p.id, child: Text(p.name)))
                        .toList(),
                    onChanged: (v) => selectedParent.value = v,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          Obx(
            () => ElevatedButton(
              onPressed: controller.isSaving.value
                  ? null
                  : () async {
                      if (nameCtrl.text.trim().isEmpty) {
                        Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final ok = await controller.save(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        parentId: selectedParent.value,
                      );
                      if (ok) Get.back();
                    },
              child: controller.isSaving.value
                  ? const SizedBox(
                      height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi'),
            ),
          ),
        ],
      ),
    );
  }
}
