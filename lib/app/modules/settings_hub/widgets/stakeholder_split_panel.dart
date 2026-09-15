import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/network/api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/data_table_card.dart';
import '../../../core/widgets/status_badge.dart';
import '../../stakeholders/controllers/stakeholders_controller.dart';
import '../../stakeholders/models/stakeholder_model.dart';
import '../../stakeholders/stakeholders_service.dart';

class StakeholderSplitPanel extends StatefulWidget {
  const StakeholderSplitPanel({super.key});

  @override
  State<StakeholderSplitPanel> createState() => _StakeholderSplitPanelState();
}

class _StakeholderSplitPanelState extends State<StakeholderSplitPanel> with AutomaticKeepAliveClientMixin {
  late final StakeholdersController controller;
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final contactPersonCtrl = TextEditingController();
  final notesCtrl = TextEditingController();
  final RxString kind = 'BINAFSI'.obs;
  int? editingId;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<StakeholdersController>()) {
      Get.put(StakeholdersController(StakeholdersService(Get.find<ApiClient>())));
    }
    controller = Get.find<StakeholdersController>();
  }

  void _resetForm() {
    editingId = null;
    nameCtrl.clear();
    phoneCtrl.clear();
    emailCtrl.clear();
    addressCtrl.clear();
    contactPersonCtrl.clear();
    notesCtrl.clear();
    kind.value = 'BINAFSI';
  }

  void _editItem(StakeholderModel item) {
    setState(() {
      editingId = item.id;
      nameCtrl.text = item.name;
      phoneCtrl.text = item.phoneNumber ?? '';
      emailCtrl.text = item.emailAddress ?? '';
      addressCtrl.text = item.address ?? '';
      contactPersonCtrl.text = item.contactPerson ?? '';
      notesCtrl.text = item.notes ?? '';
      kind.value = item.kind;
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
      kind: kind.value,
      phoneNumber: phoneCtrl.text.trim().isEmpty ? null : phoneCtrl.text.trim(),
      emailAddress: emailCtrl.text.trim().isEmpty ? null : emailCtrl.text.trim(),
      address: addressCtrl.text.trim().isEmpty ? null : addressCtrl.text.trim(),
      contactPerson: contactPersonCtrl.text.trim().isEmpty ? null : contactPersonCtrl.text.trim(),
      notes: notesCtrl.text.trim().isEmpty ? null : notesCtrl.text.trim(),
    );
    if (ok) setState(_resetForm);
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    phoneCtrl.dispose();
    emailCtrl.dispose();
    addressCtrl.dispose();
    contactPersonCtrl.dispose();
    notesCtrl.dispose();
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
            width: 360,
            child: Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: AppColors.border)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const CircleAvatar(backgroundColor: AppColors.successBg, child: Icon(Icons.handshake_outlined, color: AppColors.primaryGreen)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(editingId == null ? 'Ongeza Mdau' : 'Hariri Mdau', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                    ]),
                    const Divider(height: 28),
                    Obx(
                      () => SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'BINAFSI', label: Text('Binafsi'), icon: Icon(Icons.person_outline, size: 16)),
                          ButtonSegment(value: 'TAASISI', label: Text('Taasisi'), icon: Icon(Icons.business_outlined, size: 16)),
                        ],
                        selected: {kind.value},
                        onSelectionChanged: (s) => kind.value = s.first,
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Jina')),
                    const SizedBox(height: 14),
                    TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Namba ya Simu (hiari)')),
                    const SizedBox(height: 14),
                    TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email (hiari)')),
                    const SizedBox(height: 14),
                    TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Anwani (hiari)')),
                    const SizedBox(height: 14),
                    Obx(() => kind.value == 'TAASISI'
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: TextField(controller: contactPersonCtrl, decoration: const InputDecoration(labelText: 'Mtu wa Kuwasiliana Naye (hiari)')),
                          )
                        : const SizedBox()),
                    TextField(controller: notesCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Maelezo (hiari)')),
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
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(prefixIcon: Icon(Icons.search, size: 20), hintText: 'Search', isDense: true),
                        onSubmitted: (v) {
                          controller.searchText.value = v;
                          controller.loadAll();
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Obx(
                      () => DropdownButton<String?>(
                        value: controller.kindFilter.value,
                        hint: const Text('Aina: Wote'),
                        underline: const SizedBox(),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Wote')),
                          DropdownMenuItem(value: 'BINAFSI', child: Text('Binafsi')),
                          DropdownMenuItem(value: 'TAASISI', child: Text('Taasisi')),
                        ],
                        onChanged: controller.setKindFilter,
                      ),
                    ),
                  ],
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
                  if (controller.items.isEmpty) {
                    return const Padding(padding: EdgeInsets.symmetric(vertical: 40), child: Center(child: Text('Hakuna wadau bado.', style: TextStyle(color: AppColors.textSecondary))));
                  }
                  return DataTableCard(
                    columns: const [
                      DataColumn(label: Text('Jina')),
                      DataColumn(label: Text('Aina')),
                      DataColumn(label: Text('Simu')),
                      DataColumn(label: Text('Email')),
                      DataColumn(label: Text('Vitendo')),
                    ],
                    rows: controller.items.map((item) {
                      return DataRow(cells: [
                        DataCell(Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                        DataCell(StatusBadge(
                          item.kind == 'BINAFSI' ? 'Binafsi' : 'Taasisi',
                          color: item.kind == 'BINAFSI' ? AppColors.info : AppColors.primaryGreen,
                        )),
                        DataCell(Text(item.phoneNumber ?? '-')),
                        DataCell(Text(item.emailAddress ?? '-')),
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

  void _confirmDelete(StakeholderModel item) {
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
