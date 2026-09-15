import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/searchable_dropdown.dart';
import '../../lookup/controllers/lookup_controller.dart';
import '../../lookup/lookup_config.dart';
import '../../lookup/lookup_service.dart';
import '../../lookup/models/lookup_item_model.dart';
import '../../rulers/models/lookup_option.dart';

/// Tab-content ya "usanidi rahisi" (jina + mzazi wa hiari) - fomu ya
/// "Ongeza" iko papo hapo upande wa kushoto (siyo dialog), na orodha +
/// search upande wa kulia - kufuata muundo wa mfumo wa awali (screenshot
/// uliyoutuma: "Register Activity" + orodha ya "Sekta").
class SplitLookupPanel extends StatefulWidget {
  final LookupConfig config;
  final IconData icon;
  const SplitLookupPanel({super.key, required this.config, required this.icon});

  @override
  State<SplitLookupPanel> createState() => _SplitLookupPanelState();
}

class _SplitLookupPanelState extends State<SplitLookupPanel> with AutomaticKeepAliveClientMixin {
  late final LookupController controller;
  final nameCtrl = TextEditingController();
  final RxnInt selectedParentId = RxnInt();
  int? editingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final tag = widget.config.endpoint;
    if (!Get.isRegistered<LookupController>(tag: tag)) {
      Get.put(
        LookupController(LookupService(Get.find<ApiClient>(), widget.config.endpoint), widget.config),
        tag: tag,
      );
    }
    controller = Get.find<LookupController>(tag: tag);
  }

  void _resetForm() {
    editingId = null;
    nameCtrl.clear();
    selectedParentId.value = null;
  }

  void _editItem(LookupItemModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      selectedParentId.value = item.parentId;
    });
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await controller.save(id: editingId, name: nameCtrl.text.trim(), parentId: selectedParentId.value);
    if (ok) {
      setState(() => _resetForm());
    }
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
          // ---------- Fomu (kushoto) ----------
          SizedBox(
            width: 340,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(widget.icon, color: AppColors.primaryGreen)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            editingId == null ? 'Ongeza ${widget.config.addLabel}' : 'Hariri ${widget.config.addLabel}',
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 28),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina')),
                    if (widget.config.parentKey != null) ...[
                      const SizedBox(height: 14),
                      Obx(
                        () => SearchableDropdown(
                          label: widget.config.parentLabel ?? 'Mzazi',
                          options: controller.parentOptions.map((p) => LookupOption(p.id!, p.name)).toList(),
                          value: selectedParentId.value,
                          onChanged: (v) => selectedParentId.value = v,
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                    Row(
                      children: [
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
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // ---------- Search + Orodha (kulia) ----------
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
                  if (controller.isLoading.value) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: CircularProgressIndicator()));
                  }
                  if (controller.errorMessage.value != null) {
                    return Column(children: [
                      Text(controller.errorMessage.value!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: controller.loadAll, child: const Text('Jaribu tena')),
                    ]);
                  }
                  final list = controller.filteredItems;
                  if (list.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('Hakuna "${widget.config.title}" bado.', style: const TextStyle(color: AppColors.textSecondary))),
                    );
                  }
                  return DataTableCard(
                    columns: [
                      const DataColumn(label: Text('Jina')),
                      if (widget.config.parentKey != null) DataColumn(label: Text(widget.config.parentLabel ?? 'Mzazi')),
                      const DataColumn(label: Text('Vitendo')),
                    ],
                    rows: list.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        if (widget.config.parentKey != null) DataCell(Text(controller.parentNameOf(item.parentId))),
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

  void _confirmDelete(LookupItemModel item) {
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
