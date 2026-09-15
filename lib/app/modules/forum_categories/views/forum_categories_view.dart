import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_shell.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/page_header.dart';
import '../controllers/forum_categories_controller.dart';
import '../models/forum_category_model.dart';

class ForumCategoriesView extends GetView<ForumCategoriesController> {
  const ForumCategoriesView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppShell(
      title: 'Categories za Forum',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: PageHeader(
                  title: 'Categories za Forum',
                  subtitle: 'Simamia Categories za Fursa na Mijadala kwenye Forum.',
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => _showFormDialog(context),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Ongeza Category'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Obx(
            () => DropdownButton<String?>(
              value: controller.kindFilter.value,
              hint: const Text('Aina: Wote'),
              underline: const SizedBox(),
              items: const [
                DropdownMenuItem(value: null, child: Text('Aina Zote')),
                DropdownMenuItem(value: 'OPPORTUNITY', child: Text('Fursa')),
                DropdownMenuItem(value: 'DISCUSSION', child: Text('Mijadala')),
              ],
              onChanged: controller.setKindFilter,
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
              if (controller.categories.isEmpty) {
                return const Center(child: Text('Hakuna categories bado.', style: TextStyle(color: AppColors.textSecondary)));
              }
              return SingleChildScrollView(
                child: DataTableCard(
                  columns: const [
                    DataColumn(label: Text('Icon')),
                    DataColumn(label: Text('Jina')),
                    DataColumn(label: Text('Aina')),
                    DataColumn(label: Text('Vitendo')),
                  ],
                  rows: controller.categories.map((c) {
                    return DataRow(cells: [
                      DataCell(Text(c.icon ?? '-', style: const TextStyle(fontSize: 18))),
                      DataCell(Text(c.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      DataCell(Text(c.kind == 'OPPORTUNITY' ? 'Opportunity' : 'Discussion')),
                      DataCell(Row(children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.primaryGreen),
                          onPressed: () => _showFormDialog(context, existing: c),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.danger),
                          onPressed: () => _confirmDelete(context, c),
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

  void _confirmDelete(BuildContext context, ForumCategoryModel c) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa Category'),
        content: Text('Una uhakika unataka kufuta "${c.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.delete(c.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }

  void _showFormDialog(BuildContext context, {ForumCategoryModel? existing}) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final iconCtrl = TextEditingController(text: existing?.icon ?? '');
    final sortCtrl = TextEditingController(text: existing?.sortOrder.toString() ?? '0');
    final kindRx = RxnString(existing?.kind); // NB: HAKUNA default kiotomatiki tena
    // (zamani ilikuwa inachagua "DISCUSSION" kiotomatiki bila Admin kuchagua
    // wazi - hii ndiyo sababu iliyokuwa ikisababisha categories za "Fursa"
    // kuundwa kimakosa kama "Mjadala", na dropdown ya "Kategoria" kwenye
    // "Ongeza Fursa" kubaki tupu).

    Get.dialog(
      AlertDialog(
        title: Text(existing == null ? 'Ongeza Category' : 'Hariri Category'),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Category')),
              const SizedBox(height: 10),
              TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icon (emoji, hiari)', hintText: '💼')),
              const SizedBox(height: 10),
              Obx(
                () => DropdownButtonFormField<String>(
                  value: kindRx.value,
                  hint: const Text('Chagua aina'),
                  decoration: const InputDecoration(labelText: 'Aina'),
                  items: const [
                    DropdownMenuItem(value: 'OPPORTUNITY', child: Text('Fursa')),
                    DropdownMenuItem(value: 'DISCUSSION', child: Text('Mjadala')),
                  ],
                  onChanged: (v) => kindRx.value = v,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: sortCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Mpangilio (Sort Order)'),
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
                      if (kindRx.value == null) {
                        Get.snackbar('Kosa', 'Chagua Aina (Fursa au Mjadala).', snackPosition: SnackPosition.BOTTOM);
                        return;
                      }
                      final ok = await controller.save(
                        id: existing?.id,
                        name: nameCtrl.text.trim(),
                        icon: iconCtrl.text.trim().isEmpty ? null : iconCtrl.text.trim(),
                        kind: kindRx.value!,
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
