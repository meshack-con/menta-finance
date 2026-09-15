import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../../../core/widgets/status_badge.dart';
import '../controllers/document_types_controller.dart';
import '../models/document_type_model.dart';

class DocumentTypesView extends GetView<DocumentTypesController> {
  const DocumentTypesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Aina za Nyaraka',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Aina za Nyaraka Zinazohitajika',
                  subtitle: 'Orodha hii inamwongoza mwanachama ni nyaraka gani anapaswa kupakia (Mobile App).',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ongeza Aina ya Nyaraka'),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
              if (controller.items.isEmpty) {
                return const Center(child: Text('Hakuna aina za nyaraka bado.', style: TextStyle(color: AppColors.textSecondary)));
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Jina')),
                    DataColumn(label: Text('Maelezo')),
                    DataColumn(label: Text('Hali')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: controller.items.map((d) {
                    return DataRow(cells: [
                      DataCell(Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(SizedBox(width: 280, child: Text(d.description ?? '-', overflow: TextOverflow.ellipsis))),
                      DataCell(StatusBadge(d.isRequired ? 'Lazima' : 'Hiari', color: d.isRequired ? AppColors.danger : AppColors.neutralGray)),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          onPressed: () => _showFormDialog(context, existing: d),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, d),
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

  void _confirmDelete(BuildContext context, DocumentTypeModel d) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Aina ya Nyaraka'),
        content: Text('Una uhakika unataka kufuta "${d.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.delete(d.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {DocumentTypeModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final sortCtrl = TextEditingController(text: existing?.sortOrder.toString() ?? '0');
    final isRequiredRx = (existing?.isRequired ?? false).obs;

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza Aina ya Nyaraka' : 'Hariri Aina ya Nyaraka'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina (mfano: NIDA)')),
              const SizedBox(height: 10),
              TextField(controller: descCtrl, maxLines: 3, decoration: const InputDecoration(labelText: 'Maelezo (hiari) - kwa mwanachama kuelewa vizuri')),
              const SizedBox(height: 10),
              TextField(controller: sortCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mpangilio (Sort Order)')),
              const SizedBox(height: 10),
              Obx(
                () => SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isRequiredRx.value,
                  onChanged: (v) => isRequiredRx.value = v,
                  title: const Text('Ni Lazima?', style: TextStyle(fontSize: 14)),
                  subtitle: const Text('Mwanachama ataonyeshwa kama "LAZIMA" apakie hii', style: TextStyle(fontSize: 11)),
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
                      if (nameCtrl.text.trim().isEmpty) {
                        Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final ok = await controller.save(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                        isRequired: isRequiredRx.value,
                        sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 0,
                      );
                      if (ok) Get.back();
                    },
              child: controller.isSaving.value
                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Hifadhi'),
            ),
          ),
        ],
      ),
    );
  }
}
