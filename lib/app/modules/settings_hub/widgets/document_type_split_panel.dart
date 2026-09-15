import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../document_types/controllers/document_types_controller.dart';
import '../../document_types/document_types_service.dart';
import '../../document_types/models/document_type_model.dart';

class DocumentTypeSplitPanel extends StatefulWidget {
  const DocumentTypeSplitPanel({super.key});

  @override
  State<DocumentTypeSplitPanel> createState() => _DocumentTypeSplitPanelState();
}

class _DocumentTypeSplitPanelState extends State<DocumentTypeSplitPanel> with AutomaticKeepAliveClientMixin {
  late final DocumentTypesController controller;
  final nameCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final sortCtrl = TextEditingController(text: '0');
  final RxBool isRequired = false.obs;
  int? editingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<DocumentTypesController>()) {
      Get.put(DocumentTypesController(DocumentTypesService(Get.find<ApiClient>())));
    }
    controller = Get.find<DocumentTypesController>();
  }

  void _resetForm() {
    editingId = null;
    nameCtrl.clear();
    descCtrl.clear();
    sortCtrl.text = '0';
    isRequired.value = false;
  }

  void _editItem(DocumentTypeModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      descCtrl.text = item.description ?? '';
      sortCtrl.text = item.sortOrder.toString();
      isRequired.value = item.isRequired;
    });
  }

  Future<void> _submit() async {
    if (nameCtrl.text.trim().isEmpty) {
      Get.snackbar('Kosa', 'Jina haliwezi kuwa tupu.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    final ok = await controller.save(
      id: editingId,
      name: nameCtrl.text.trim(),
      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
      isRequired: isRequired.value,
      sortOrder: int.tryParse(sortCtrl.text.trim()) ?? 0,
    );
    if (ok) setState(_resetForm);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descCtrl.dispose();
    sortCtrl.dispose();
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
                      const CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(Icons.folder_special_outlined, color: AppColors.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(editingId == null ? 'Ongeza Aina ya Nyaraka' : 'Hariri Aina', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    ]),
                    const Divider(height: 28),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name (mfano: NIDA)')),
                    const SizedBox(height: 14),
                    TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Maelezo (hiari)')),
                    const SizedBox(height: 14),
                    TextField(controller: sortCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Mpangilio')),
                    const SizedBox(height: 6),
                    Obx(
                      () => SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: isRequired.value,
                        onChanged: (v) => isRequired.value = v,
                        title: const Text('Ni Lazima?', style: TextStyle(fontSize: 13)),
                      ),
                    ),
                    const SizedBox(height: 14),
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
              if (controller.items.isEmpty) {
                return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Hakuna aina za nyaraka bado.', style: TextStyle(color: AppColors.textSecondary))));
              }
              return DataTableCard(
                columns: const [
                  DataColumn(label: Text('Jina')),
                  DataColumn(label: Text('Maelezo')),
                  DataColumn(label: Text('Hali')),
                  DataColumn(label: Text('Vitendo')),
                ],
                rows: controller.items.map((d) {
                  return DataRow(cells: [
                    DataCell(Text(d.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(SizedBox(width: 260, child: Text(d.description ?? '-', overflow: TextOverflow.ellipsis))),
                    DataCell(StatusBadge(d.isRequired ? 'Lazima' : 'Hiari', color: d.isRequired ? AppColors.danger : AppColors.neutralGray)),
                    DataCell(Row(children: [
                      TextButton.icon(
                        onPressed: () => _editItem(d),
                        icon: const Icon(Icons.edit_outlined, size: 16, color: AppColors.primaryGreen),
                        label: const Text('Edit', style: TextStyle(color: AppColors.primaryGreen)),
                      ),
                      TextButton.icon(
                        onPressed: () => _confirmDelete(d),
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

  void _confirmDelete(DocumentTypeModel d) {
    Get.dialog(
      AlertDialog(
        title: const Text('Futa'),
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
}
