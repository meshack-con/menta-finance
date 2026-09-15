import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../../../core/widgets/status_badge.dart';
import '../models/admin_position_model.dart';
import '../models/lookup_option.dart';
import '../models/ruler_attachment_model.dart';
import '../ruler_service.dart';

/// Dialog ya Admin kuona kila kitu kuhusu Ruler mmoja: picha ya profile,
/// nyaraka zake (preview/download), na HISTORIA KAMILI ya uongozi wake
/// (nafasi za sasa, za zamani, na zinazosubiri uthibitisho).
/// Inafunguliwa kutoka RulerListView.
class RulerDocumentsDialog extends StatefulWidget {
  final int rulerId;
  final String rulerName;
  const RulerDocumentsDialog({super.key, required this.rulerId, required this.rulerName});

  @override
  State<RulerDocumentsDialog> createState() => _RulerDocumentsDialogState();
}

class _RulerDocumentsDialogState extends State<RulerDocumentsDialog> {
  final _service = Get.find<RulerService>();

  bool _isLoading = true;
  List<int>? _photoBytes;
  List<RulerAttachmentModel> _attachments = [];
  int? _busyAttachmentId;

  List<AdminPositionModel> _positions = [];
  Map<int, String> _leadershipNames = {};
  Map<int, String> _regionNames = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    _photoBytes = await _service.getPhotoBytes(widget.rulerId);
    try {
      _attachments = await _service.listAttachments(widget.rulerId);
    } catch (_) {
      _attachments = [];
    }
    try {
      _positions = await _service.listPositionsForRuler(widget.rulerId);
      final leaderships = await _service.listLeaderships();
      final regions = await _service.listRegions();
      _leadershipNames = {for (final l in leaderships) l.id: l.name};
      _regionNames = {for (final r in regions) r.id: r.name};
    } catch (_) {
      _positions = [];
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _preview(RulerAttachmentModel a) async {
    final name = (a.attachmentName ?? '').toLowerCase();
    final isImage = name.endsWith('.jpg') || name.endsWith('.jpeg') || name.endsWith('.png');
    if (!isImage) {
      Get.snackbar('Haiwezekani', 'PDF haiwezi ku-preview hapa - bofya "Pakua".', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _busyAttachmentId = a.id);
    try {
      final bytes = await _service.previewAttachmentBytes(a.id);
      Get.dialog(
        Dialog(
          child: SizedBox(
            width: 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppBar(
                  title: Text(a.attachmentName ?? 'Picha'),
                  automaticallyImplyLeading: false,
                  actions: [IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back())],
                ),
                Image.memory(Uint8List.fromList(bytes)),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _busyAttachmentId = null);
    }
  }

  Future<void> _download(RulerAttachmentModel a) async {
    setState(() => _busyAttachmentId = a.id);
    try {
      final bytes = await _service.downloadAttachmentBytes(a.id);
      downloadBytesAsFile(bytes, a.attachmentName ?? 'faili_${a.id}');
    } finally {
      if (mounted) setState(() => _busyAttachmentId = null);
    }
  }

  bool get _isCurrentlyLeader => _positions.any((p) => p.isVerified && p.isCurrentlyOngoing);

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd/MM/yyyy');
    final currentPositions = _positions.where((p) => p.isVerified && p.isCurrentlyOngoing).toList();
    final pastPositions = _positions.where((p) => p.isVerified && !p.isCurrentlyOngoing).toList();
    final pendingPositions = _positions.where((p) => !p.isVerified).toList();

    return Dialog(
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              : ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 640),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text('Maelezo Zaidi - ${widget.rulerName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                            ),
                            IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                          ],
                        ),
                        const Divider(),
                        Center(
                          child: _photoBytes != null
                              ? CircleAvatar(radius: 50, backgroundImage: MemoryImage(Uint8List.fromList(_photoBytes!)))
                              : const CircleAvatar(radius: 50, backgroundColor: AppColors.neutralGrayBg, child: Icon(Icons.person, size: 40, color: AppColors.neutralGray)),
                        ),
                        const SizedBox(height: 10),
                        Center(
                          child: StatusBadge(
                            _isCurrentlyLeader ? 'Hali ya Sasa: Kiongozi' : 'Hali ya Sasa: Mwanachama wa Kawaida',
                            color: _isCurrentlyLeader ? AppColors.success : AppColors.neutralGray,
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ---------- Historia ya Uongozi ----------
                        const Text('Historia ya Uongozi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                        const SizedBox(height: 8),
                        if (_positions.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Hajawahi kuwa na nafasi yoyote ya uongozi.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        else ...[
                          if (currentPositions.isNotEmpty) ...[
                            const Text('Sasa Hivi', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.success)),
                            ...currentPositions.map((p) => _PositionTile(position: p, leadershipNames: _leadershipNames, regionNames: _regionNames, dateFmt: dateFmt, badge: 'Sasa', badgeColor: AppColors.success)),
                            const SizedBox(height: 10),
                          ],
                          if (pendingPositions.isNotEmpty) ...[
                            const Text('Inasubiri Uthibitisho', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.warning)),
                            ...pendingPositions.map((p) => _PositionTile(position: p, leadershipNames: _leadershipNames, regionNames: _regionNames, dateFmt: dateFmt, badge: 'Pending', badgeColor: AppColors.warning)),
                            const SizedBox(height: 10),
                          ],
                          if (pastPositions.isNotEmpty) ...[
                            const Text('Historia (Zamani)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: AppColors.neutralGray)),
                            ...pastPositions.map((p) => _PositionTile(position: p, leadershipNames: _leadershipNames, regionNames: _regionNames, dateFmt: dateFmt, badge: 'Historia', badgeColor: AppColors.neutralGray)),
                          ],
                        ],

                        const SizedBox(height: 20),
                        const Text('Nyaraka Zilizopakiwa', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                        const SizedBox(height: 8),
                        if (_attachments.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Text('Hakuna nyaraka zilizopakiwa.', style: TextStyle(color: AppColors.textSecondary)),
                          )
                        else
                          ..._attachments.map((a) {
                            final busy = _busyAttachmentId == a.id;
                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(Icons.description_outlined, color: AppColors.primaryGreen),
                              title: Text(a.attachmentName ?? 'Faili', style: const TextStyle(fontSize: 13)),
                              subtitle: a.description != null ? Text(a.description!, style: const TextStyle(fontSize: 11)) : null,
                              trailing: busy
                                  ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.visibility_outlined, size: 18), onPressed: () => _preview(a)),
                                        IconButton(icon: const Icon(Icons.download_outlined, size: 18), onPressed: () => _download(a)),
                                      ],
                                    ),
                            );
                          }),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _PositionTile extends StatelessWidget {
  final AdminPositionModel position;
  final Map<int, String> leadershipNames;
  final Map<int, String> regionNames;
  final DateFormat dateFmt;
  final String badge;
  final Color badgeColor;

  const _PositionTile({
    required this.position,
    required this.leadershipNames,
    required this.regionNames,
    required this.dateFmt,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    final leadershipName = leadershipNames[position.leadershipId] ?? 'Nafasi #${position.leadershipId}';
    final regionName = regionNames[position.regionId] ?? 'Mkoa #${position.regionId}';
    final period = '${position.startDate != null ? dateFmt.format(position.startDate!) : "-"} - ${position.endDate != null ? dateFmt.format(position.endDate!) : "Sasa"}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 16, color: badgeColor),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$leadershipName - $regionName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                Text(period, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ],
            ),
          ),
          StatusBadge(badge, color: badgeColor),
        ],
      ),
    );
  }
}
