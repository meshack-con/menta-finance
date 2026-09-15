import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../controllers/education_hierarchy_controller.dart';
import '../models/education_level_model.dart';

class EducationLevelSplitPanel extends StatefulWidget {
  const EducationLevelSplitPanel({super.key});

  @override
  State<EducationLevelSplitPanel> createState() => _EducationLevelSplitPanelState();
}

class _EducationLevelSplitPanelState extends State<EducationLevelSplitPanel> with AutomaticKeepAliveClientMixin {
  late final EducationHierarchyController controller;
  final nameCtrl = TextEditingController();
  final RxnInt selectedRegionId = RxnInt();
  final RxnInt selectedBranchId = RxnInt();
  int? editingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<EducationHierarchyController>()) {
      Get.put(EducationHierarchyController(Get.find<ApiClient>()));
    }
    controller = Get.find<EducationHierarchyController>();
  }

  void _resetForm() {
    editingId = null;
    nameCtrl.clear();
    selectedRegionId.value = null;
    selectedBranchId.value = null;
  }

  void _editItem(EducationLevelModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      selectedBranchId.value = item.branchId;
      selectedRegionId.value = controller.branchRegionOf[item.branchId];
    });
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await controller.saveLevel(id: editingId, name: nameCtrl.text.trim(), branchId: selectedBranchId.value);
    if (ok) setState(_resetForm);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 340,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(Icons.school_outlined, color: AppColors.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(editingId == null ? 'Ongeza Ngazi ya Elimu' : 'Hariri Ngazi', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    ]),
                    const Divider(height: 28),
                    Obx(
                      () => SearchableDropdown(
                        label: 'Mkoa',
                        options: controller.regions,
                        value: selectedRegionId.value,
                        onChanged: (v) {
                          selectedRegionId.value = v;
                          selectedBranchId.value = null; // mkoa ukibadilika, tawi linaanza upya
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => SearchableDropdown(
                        label: selectedRegionId.value == null ? 'Tawi (chagua mkoa kwanza)' : 'Tawi',
                        options: controller.branchesForRegion(selectedRegionId.value),
                        value: selectedBranchId.value,
                        onChanged: (v) => selectedBranchId.value = v,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Ngazi (mfano: Shahada, Astashahada)')),
                    const SizedBox(height: 20),
                    Row(children: [
                      Expanded(
                        child: Obx(
                          () => ElevatedButton(
                            onPressed: controller.isSaving.value ? null : _submit,
                            child: controller.isSaving.value
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : Text(editingId == null ? 'Wasilisha' : 'Hifadhi Mabadiliko'),
                          ),
                        ),
                      ),
                      if (editingId != null) ...[
                        const SizedBox(width: 8),
                        TextButton(onPressed: () => setState(_resetForm), child: const Text('Ghairi')),
                      ],
                    ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Obx(() {
              if (controller.isLoading.value) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
              if (controller.errorMessage.value != null) {
                return Column(children: [
                  Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 10),
                  ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                ]);
              }
              if (controller.levels.isEmpty) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Hakuna ngazi za elimu bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              return DataTableCard(
                columns: const [
                  DataColumn(label: Text('Jina')),
                  DataColumn(label: Text('Tawi')),
                  DataColumn(label: Text('Mkoa')),
                  DataColumn(label: Text('Vitendo')),
                ],
                rows: controller.levels.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(controller.branchName(item.branchId))),
                    DataCell(Text(controller.regionName(controller.regionOfLevel(item)))),
                    DataCell(Row(children: [
                      TextButton.icon(
                        onPressed: () => _editItem(item),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryGreen),
                        label: const Text('Edit', style: TextStyle(color: AppColors.primaryGreen)),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(item),
                        icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                        label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      ),
                    ])),
                  ]);
                }).toList(),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(EducationLevelModel item) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa'),
        content: Text('Una uhakika unataka kufuta "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Ghairi')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              Get.back();
              controller.deleteLevel(item.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}
