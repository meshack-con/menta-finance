import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/status_badge.dart';
import '../ruler_service.dart';

/// Ukurasa MMOJA mkubwa unaokusanya KILA KITU kuhusu Ruler mmoja: Picha,
/// Taarifa Binafsi, Taarifa za Makazi, Uongozi, Ajira, Elimu, Mafunzo, na
/// Nyaraka - unafuata muundo wa "Member Preview Profile" wa mfumo wa awali
/// (screenshot uliyoutuma), ukiwa umeboreshwa zaidi kwa rangi na alama za
/// hali ("Inayotumika").
class RulerProfileDialog extends StatefulWidget {
  final int rulerId;
  final String rulerName;
  const RulerProfileDialog({super.key, required this.rulerId, required this.rulerName});

  @override
  State<RulerProfileDialog> createState() => _RulerProfileDialogState();
}

class _RulerProfileDialogState extends State<RulerProfileDialog> {
  final _service = Get.find<RulerService>();

  bool _isLoading = true;
  String? _error;
  List<int>? _photoBytes;
  Map<String, dynamic>? _cv;
  Map<int, String> _regionNames = {};
  Map<int, String> _branchNames = {};
  Map<int, String> _leadershipNames = {};
  int? _busyAttachmentId;
  bool _isDownloadingCv = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _photoBytes = await _service.getPhotoBytes(widget.rulerId);
      _cv = await _service.getCv(widget.rulerId);
      final regions = await _service.listRegions();
      final branches = await _service.listBranches();
      final leaderships = await _service.listLeaderships();
      _regionNames = {for (final r in regions) r.id: r.name};
      _branchNames = {for (final b in branches) b.id: b.name};
      _leadershipNames = {for (final l in leaderships) l.id: l.name};
    } catch (e) {
      _error = 'Imeshindikana kupakia taarifa.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> _section(String key) {
    final list = _cv?[key];
    if (list is List) return list.cast<Map<String, dynamic>>();
    return [];
  }

  bool _isCurrentlyActive(Map<String, dynamic> row) {
    final endDate = row['end_date'];
    if (endDate == null) return true;
    final parsed = DateTime.tryParse(endDate.toString());
    if (parsed == null) return true;
    return parsed.isAfter(DateTime.now());
  }

  Future<void> _downloadCv() async {
    setState(() => _isDownloadingCv = true);
    try {
      final bytes = await _service.getCvPdfBytes(widget.rulerId);
      downloadBytesAsFile(Uint8List.fromList(bytes), 'CV_${widget.rulerName.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kupakua CV.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isDownloadingCv = false);
    }
  }

  Future<void> _previewAttachment(Map<String, dynamic> a) async {
    final id = a['id'] as int;
    final name = (a['attachment_name']?.toString() ?? '').toLowerCase();
    setState(() => _busyAttachmentId = id);
    try {
      if (name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png')) {
        final bytes = await _service.previewAttachmentBytes(id);
        Get.dialog(
          Dialog(
            child: SizedBox(
              width: 500,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                AppBar(
                  title: Text(a['attachment_name']?.toString() ?? 'Picha'),
                  automaticallyImplyLeading: false,
                  actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back())],
                ),
                Image.memory(Uint8List.fromList(bytes)),
              ]),
            ),
          ),
        );
      } else {
        final bytes = await _service.downloadAttachmentBytes(id);
        downloadBytesAsFile(Uint8List.fromList(bytes), a['attachment_name']?.toString() ?? 'faili_$id');
      }
    } finally {
      if (mounted) setState(() => _busyAttachmentId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');

    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      child: SizedBox(
        width: 1200,
        height: 780,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text(_error!, style: const TextStyle(color: AppColors.danger)),
                      const SizedBox(height: 10),
                      ElevatedButton(onPressed: _loadAll, child: const Text('Jaribu tena')),
                    ]),
                  )
                : Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 18, 16, 12),
                        child: Row(children: [
                          Expanded(child: Text(widget.rulerName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800))),
                          _isDownloadingCv
                              ? const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : ElevatedButton.icon(
                                  onPressed: _downloadCv,
                                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 17),
                                  label: const Text('Pakua CV'),
                                ),
                          const SizedBox(width: 12),
                          TextButton(onPressed: () => Get.back(), child: const Text('CLOSE')),
                        ]),
                      ),
                      const Divider(height: 1),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ---------- Kushoto: Picha + Taarifa Binafsi ----------
                              SizedBox(
                                width: 320,
                                child: SingleChildScrollView(
                                  child: _PersonalInfoPanel(photoBytes: _photoBytes, profile: (_cv?['profile'] as Map<String, dynamic>?) ?? {}),
                                ),
                              ),
                              const SizedBox(width: 20),
                              // ---------- Kulia: Sections zote ----------
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _SectionCard(
                                        title: 'Taarifa za Makazi',
                                        icon: Icons.location_on_outlined,
                                        columns: const ['Mkoa', 'Tawi', 'Inayotumika'],
                                        rows: _section('locations').map((loc) {
                                          return [
                                            _regionNames[loc['region_id']] ?? '-',
                                            _branchNames[loc['branch_id']] ?? '-',
                                            '',
                                          ];
                                        }).toList(),
                                        activeFlags: _section('locations').map((e) => true).toList(),
                                      ),
                                      _SectionCard(
                                        title: 'Taarifa za Uongozi',
                                        icon: Icons.emoji_events_outlined,
                                        columns: const ['Nafasi', 'Mkoa', 'Kuanzia', 'Hadi', 'Hali', 'Inayotumika'],
                                        rows: _section('positions').map((p) {
                                          final verified = p['is_verified'] == true;
                                          return [
                                            _leadershipNames[p['leadership_id']] ?? '#${p['leadership_id']}',
                                            _regionNames[p['region_id']] ?? '-',
                                            p['start_date']?.toString() ?? '-',
                                            p['end_date']?.toString() ?? 'Sasa',
                                            verified ? 'Imethibitishwa' : 'Inasubiri',
                                            '',
                                          ];
                                        }).toList(),
                                        activeFlags: _section('positions').map(_isCurrentlyActive).toList(),
                                      ),
                                      _SectionCard(
                                        title: 'Taarifa za Ajira',
                                        icon: Icons.work_outline,
                                        columns: const ['Ajira', 'Taasisi', 'Nafasi', 'Kuanzia', 'Hadi', 'Inayotumika'],
                                        rows: _section('employments').map((e) {
                                          return [
                                            e['employment']?.toString() ?? '-',
                                            e['place']?.toString() ?? '-',
                                            e['title']?.toString() ?? '-',
                                            e['start_date']?.toString() ?? '-',
                                            e['end_date']?.toString() ?? '-',
                                            '',
                                          ];
                                        }).toList(),
                                        activeFlags: _section('employments').map(_isCurrentlyActive).toList(),
                                      ),
                                      _SectionCard(
                                        title: 'Taarifa za Elimu',
                                        icon: Icons.school_outlined,
                                        columns: const ['Mkoa', 'Taasisi', 'Kiwango', 'Kozi', 'Kuanzia', 'Hadi', 'Inayotumika'],
                                        rows: _section('educations').map((e) {
                                          return [
                                            e['region']?.toString() ?? '-',
                                            e['institute']?.toString() ?? '-',
                                            e['education_level']?.toString() ?? '-',
                                            e['education_program']?.toString() ?? '-',
                                            e['start_date']?.toString() ?? '-',
                                            e['end_date']?.toString() ?? '-',
                                            '',
                                          ];
                                        }).toList(),
                                        activeFlags: _section('educations').map(_isCurrentlyActive).toList(),
                                      ),
                                      _SectionCard(
                                        title: 'Taarifa za Mafunzo',
                                        icon: Icons.military_tech_outlined,
                                        columns: const ['Aina', 'Jina la Mafunzo', 'Mahali', 'Kuanzia', 'Hadi', 'Inayotumika'],
                                        rows: _section('trainings').map((t) {
                                          return [
                                            t['training_type']?.toString() ?? '-',
                                            t['training_name']?.toString() ?? '-',
                                            t['location']?.toString() ?? '-',
                                            t['start_date']?.toString() ?? '-',
                                            t['end_date']?.toString() ?? '-',
                                            '',
                                          ];
                                        }).toList(),
                                        activeFlags: _section('trainings').map(_isCurrentlyActive).toList(),
                                      ),
                                      // ---------- Nyaraka (kitufe cha "Fungua Faili") ----------
                                      _DocumentsCard(
                                        attachments: _section('attachments'),
                                        busyId: _busyAttachmentId,
                                        onOpen: _previewAttachment,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _PersonalInfoPanel extends StatelessWidget {
  final List<int>? photoBytes;
  final Map<String, dynamic> profile;
  const _PersonalInfoPanel({required this.photoBytes, required this.profile});

  @override
  Widget build(BuildContext context) {
    Widget row(String label, String? value) => Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(color: AppColors.primaryGreen, fontWeight: FontWeight.w700, fontSize: 12.5)),
              const SizedBox(height: 2),
              Text((value == null || value.isEmpty) ? '-' : value, style: const TextStyle(fontSize: 13.5)),
            ],
          ),
        );

    final fullName = '${profile['first_name'] ?? ''} ${profile['last_name'] ?? ''}'.trim();
    final gender = profile['gender'] == 'Male' ? 'Me' : (profile['gender'] == 'Female' ? 'Ke' : profile['gender']?.toString());

    String registeredByLabel() {
      final type = profile['registered_by_type']?.toString();
      final name = profile['registered_by_name']?.toString();
      switch (type) {
        case 'SELF':
          return 'Mwenyewe (kupitia Mobile App)';
        case 'ADMIN':
          return name != null && name.isNotEmpty ? 'Admin - $name' : 'Admin';
        case 'MSAJILI':
          return name != null && name.isNotEmpty ? 'Msajili - $name' : 'Msajili';
        default:
          return '-';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: photoBytes != null
                ? CircleAvatar(radius: 55, backgroundImage: MemoryImage(Uint8List.fromList(photoBytes!)))
                : const CircleAvatar(radius: 55, backgroundColor: AppColors.avatarBg, child: Icon(Icons.person, size: 50, color: AppColors.primaryGreen)),
          ),
          const SizedBox(height: 18),
          const Text('Taarifa Binafsi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          const Divider(height: 22),
          row('Jina', fullName),
          row('Jina Lingine', profile['other_name']?.toString()),
          row('Jinsia', gender),
          row('Tarehe ya Kuzaliwa', profile['date_of_birth']?.toString()),
          row('Namba ya Simu', profile['phone_number']?.toString()),
          row('Barua Pepe', profile['email_address']?.toString()),
          row('Namba ya Uwanachama (CCM)', profile['membership_code']?.toString()),
          row('Mkoa', profile['region_name']?.toString()),
          row('Tawi', profile['institute_name']?.toString()),
          row('Hadhi', profile['leadership_status']?.toString()),
          row('Alisajiliwa Na', registeredByLabel()),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<String> columns;
  final List<List<String>> rows;
  final List<bool> activeFlags;

  const _SectionCard({required this.title, required this.icon, required this.columns, required this.rows, required this.activeFlags});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hakuna taarifa.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowHeight: 34,
                dataRowMinHeight: 36,
                dataRowMaxHeight: 44,
                columns: [for (final c in columns) DataColumn(label: Text(c, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)))],
                rows: [
                  for (int i = 0; i < rows.length; i++)
                    DataRow(cells: [
                      for (int j = 0; j < rows[i].length; j++)
                        DataCell(
                          j == rows[i].length - 1
                              ? Icon(
                                  (i < activeFlags.length && activeFlags[i]) ? Icons.check_circle : Icons.history,
                                  size: 16,
                                  color: (i < activeFlags.length && activeFlags[i]) ? AppColors.success : AppColors.neutralGray,
                                )
                              : Text(rows[i][j], style: const TextStyle(fontSize: 12.5)),
                        ),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentsCard extends StatelessWidget {
  final List<Map<String, dynamic>> attachments;
  final int? busyId;
  final Future<void> Function(Map<String, dynamic>) onOpen;

  const _DocumentsCard({required this.attachments, required this.busyId, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.description_outlined, size: 17, color: AppColors.primaryGreen),
            SizedBox(width: 8),
            Text('Taarifa za Nyaraka', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 10),
          if (attachments.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text('Hakuna nyaraka zilizopakiwa.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary)),
            )
          else
            ...attachments.map((a) {
              final id = a['id'] as int;
              final busy = busyId == id;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Expanded(child: Text(a['attachment_name']?.toString() ?? 'Faili', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600))),
                    Expanded(child: Text(a['description']?.toString() ?? 'Hakuna Maelezo', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary))),
                    busy
                        ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton.icon(
                            onPressed: () => onOpen(a),
                            icon: const Icon(Icons.picture_as_pdf_outlined, size: 16, color: AppColors.danger),
                            label: const Text('Fungua Faili', style: TextStyle(color: AppColors.danger, fontSize: 12.5)),
                          ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
