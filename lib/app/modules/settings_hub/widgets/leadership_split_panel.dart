import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../leadership/controllers/leadership_controller.dart';
import '../../leadership/leadership_service.dart';
import '../../leadership/models/leadership_model.dart';

class LeadershipSplitPanel extends StatefulWidget {
  const LeadershipSplitPanel({super.key});

  @override
  State<LeadershipSplitPanel> createState() => _LeadershipSplitPanelState();
}

class _LeadershipSplitPanelState extends State<LeadershipSplitPanel> with AutomaticKeepAliveClientMixin {
  late final LeadershipController controller;
  final nameCtrl = TextEditingController();
  final numberCtrl = TextEditingController();
  final sectionCtrl = TextEditingController();
  final RxnInt selectedTitleId = RxnInt();
  int? editingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<LeadershipController>()) {
      Get.put(LeadershipController(LeadershipService(Get.find<ApiClient>())));
    }
    controller = Get.find<LeadershipController>();
  }

  void _resetForm() {
    editingId = null;
    nameCtrl.clear();
    numberCtrl.clear();
    sectionCtrl.clear();
    selectedTitleId.value = null;
  }

  void _editItem(LeadershipModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      numberCtrl.text = item.number?.toString() ?? '';
      sectionCtrl.text = item.section ?? '';
      selectedTitleId.value = item.titleId;
    });
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty || selectedTitleId.value == null) {
      Get.snackbar('Kosa', 'Jina la Nafasi na Cheo ni lazima.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await controller.save(
      id: editingId,
      name: nameCtrl.text.trim(),
      number: int.tryParse(numberCtrl.text.trim()),
      section: sectionCtrl.text.trim().isEmpty ? null : sectionCtrl.text.trim(),
      titleId: selectedTitleId.value!,
    );
    if (ok) setState(_resetForm);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    numberCtrl.dispose();
    sectionCtrl.dispose();
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
                      const CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(Icons.workspace_premium_outlined, color: AppColors.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(editingId == null ? 'Ongeza Nafasi ya Uongozi' : 'Hariri Nafasi', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    ]),
                    const Divider(height: 28),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina la Nafasi')),
                    const SizedBox(height: 14),
                    Obx(
                      () => DropdownButtonFormField<int>(
                        value: selectedTitleId.value,
                        decoration: const InputDecoration(labelText: 'Cheo'),
                        items: controller.titles.map((t) => DropdownMenuItem(value: t.id, child: Text(t.name))).toList(),
                        onChanged: (v) => selectedTitleId.value = v,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: numberCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Namba (hiari)')),
                    const SizedBox(height: 14),
                    TextField(controller: sectionCtrl, decoration: const InputDecoration(labelText: 'Sehemu (hiari)')),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 20), hintText: 'Search', isDense: true),
                  onChanged: (v) => controller.searchText.value = v,
                ),
                const SizedBox(height: 14),
                Obx(() {
                  if (controller.isLoading.value) return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                  if (controller.errorMessage.value != null) {
                    return Column(children: [
                      Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                    ]);
                  }
                  final list = controller.filteredItems;
                  if (list.isEmpty) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Hakuna nafasi za uongozi bado.', style: TextStyle(color: AppColors.textSecondary))));
                  }
                  return DataTableCard(
                    columns: const [
                      DataColumn(label: Text('Jina')),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(LeadershipModel item) {
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
              controller.delete(item.id!);
            },
            child: const Text('Futa'),
          ),
        ],
      ),
    );
  }
}
