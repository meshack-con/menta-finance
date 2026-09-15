import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/leadership_controller.dart';
import '../models/leadership_model.dart';

class LeadershipView extends GetView<LeadershipController> {
  const LeadershipView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Nafasi za Uongozi',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Nafasi za Uongozi',
                  subtitle: 'Simamia nafasi za uongozi zinazoweza kutolewa kwa wanachama.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ongeza Nafasi'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: 340,
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search, size: 20),
                hintText: 'Jina, sehemu au cheo...',
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
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                    const SizedBox(height: 10),
                    ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                  ]),
                );
              }
              final list = controller.filteredItems;
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    controller.searchText.value.isEmpty ? 'Hakuna nafasi za uongozi bado.' : 'Hakuna matokeo.',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                );
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Jina la Nafasi')),
                    DataColumn(label: Text('Namba')),
                    DataColumn(label: Text('Sehemu')),
                    DataColumn(label: Text('Cheo')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: list.map((item) {
                    return DataRow(cells: [
                      DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(item.number?.toString() ?? '-')),
                      DataCell(Text(item.section ?? '-')),
                      DataCell(Text(controller.titleNameOf(item.titleId))),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          onPressed: () => _showFormDialog(context, existing: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, item),
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

  void _confirmDelete(BuildContext context, LeadershipModel item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Nafasi'),
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

  void _showFormDialog(BuildContext context, {LeadershipModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final numberCtrl = TextEditingController(text: existing?.number?.toString() ?? '');
    final sectionCtrl = TextEditingController(text: existing?.section ?? '');
    final selectedTitleId = RxnInt(existing?.titleId);

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza Nafasi ya Uongozi' : 'Hariri Nafasi ya Uongozi'),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Nafasi')),
              const SizedBox(height: 10),
              TextField(
                controller: numberCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Namba (hiari)'),
              ),
              const SizedBox(height: 10),
              TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Sehemu (hiari)')),
              const SizedBox(height: 10),
              Obx(
                () => DropdownButtonFormField<int>(
                  value: selectedTitleId.value,
                  decoration: const InputDecoration(labelText: 'Chagua Cheo'),
                  items: controller.titles.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                  onChanged: (v) => selectedTitleId.value = v,
                ),
              ),
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
                      if (nameCtrl.text.trim().isEmpty || selectedTitleId.value == null) {
                        Get.snackbar('Kosa', 'Jina na Cheo ni lazima.', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final ok = await controller.save(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        number: int.tryParse(numberCtrl.text.trim()),
                        section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
                        titleId: selectedTitleId.value!,
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
