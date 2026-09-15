import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../rulers/models/lookup_option.dart';
import '../controllers/education_hierarchy_controller.dart';
import '../models/education_program_model.dart';

class EducationProgramSplitPanel extends StatefulWidget {
  const EducationProgramSplitPanel({super.key});

  @override
  State<EducationProgramSplitPanel> createState() => _EducationProgramSplitPanelState();
}

class _EducationProgramSplitPanelState extends State<EducationProgramSplitPanel> with AutomaticKeepAliveClientMixin {
  late final EducationHierarchyController controller;
  final nameCtrl = TextEditingController();
  final RxnInt selectedRegionId = RxnInt();
  final RxnInt selectedBranchId = RxnInt();
  final RxnInt selectedLevelId = RxnInt();
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
    selectedLevelId.value = null;
  }

  void _editItem(EducationProgramModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      selectedLevelId.value = item.educationLevelId;
      selectedBranchId.value = controller.branchOfProgram(item);
      selectedRegionId.value = controller.branchRegionOf[selectedBranchId.value];
    });
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (selectedLevelId.value == null) {
      Get.snackbar('Kosa', 'Chagua Ngazi ya Elimu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await controller.saveProgram(id: editingId, name: nameCtrl.text.trim(), educationLevelId: selectedLevelId.value);
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
                      const CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(Icons.menu_book_outlined, color: AppColors.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(editingId == null ? 'Ongeza Programu' : 'Hariri Programu', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    ]),
                    const Divider(height: 28),
                    Obx(
                      () => SearchableDropdown(
                        label: 'Mkoa',
                        options: controller.regions,
                        value: selectedRegionId.value,
                        onChanged: (v) {
                          selectedRegionId.value = v;
                          selectedBranchId.value = null;
                          selectedLevelId.value = null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(
                      () => SearchableDropdown(
                        label: selectedRegionId.value == null ? 'Tawi (chagua mkoa kwanza)' : 'Tawi',
                        options: controller.branchesForRegion(selectedRegionId.value),
                        value: selectedBranchId.value,
                        onChanged: (v) {
                          selectedBranchId.value = v;
                          selectedLevelId.value = null;
                        },
                      ),
                    ),
                    const SizedBox(height: 14),
                    Obx(() {
                      final filteredLevels = controller.levelsForBranch(selectedBranchId.value);
                      final hasUnfilteredLevels = controller.levels.isNotEmpty;
                      final isFallback = selectedBranchId.value != null && filteredLevels.isEmpty && hasUnfilteredLevels;
                      // Ikiwa hakuna Ngazi iliyounganishwa na Tawi hili, onyesha
                      // ZOTE badala ya kuacha dropdown tupu isiyoeleweka - bora
                      // mtumiaji aone chaguo (na ujumbe unaomweleza kwa nini)
                      // kuliko afikirie mfumo "haufanyi kazi".
                      final effectiveLevels = isFallback ? controller.levels : filteredLevels;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SearchableDropdown(
                            label: selectedBranchId.value == null ? 'Ngazi ya Elimu (chagua tawi kwanza)' : 'Ngazi ya Elimu',
                            options: effectiveLevels.map((l) => LookupOption(l.id!, l.name)).toList(),
                            value: selectedLevelId.value,
                            onChanged: (v) => selectedLevelId.value = v,
                          ),
                          if (isFallback) ...[
                            const SizedBox(height: 6),
                            const Text(
                              'Hakuna Ngazi ya Elimu iliyounganishwa na Tawi hili - zinazoonyeshwa hapo juu ni ZOTE bila kuchuja. Nenda tab "Ngazi ya Elimu" kuhariri (Edit) na kuchagua Mkoa/Tawi sahihi ili ichujike ipasavyo.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.danger),
                            ),
                          ],
                        ],
                      );
                    }),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Programu (mfano: Sayansi ya Kompyuta)')),
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
              if (controller.programs.isEmpty) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Hakuna programu bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              return DataTableCard(
                columns: const [
                  DataColumn(label: Text('Jina')),
                  DataColumn(label: Text('Ngazi ya Elimu')),
                  DataColumn(label: Text('Tawi')),
                  DataColumn(label: Text('Mkoa')),
                  DataColumn(label: Text('Vitendo')),
                ],
                rows: controller.programs.map((item) {
                  return DataRow(cells: [
                    DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(controller.levelName(item.educationLevelId))),
                    DataCell(Text(controller.branchName(controller.branchOfProgram(item)))),
                    DataCell(Text(controller.regionName(controller.regionOfProgram(item)))),
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

  void _confirmDelete(EducationProgramModel item) {
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
              controller.deleteProgram(item.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}
