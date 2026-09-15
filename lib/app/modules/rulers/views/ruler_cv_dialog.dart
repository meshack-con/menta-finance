import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/web_download.dart';
import '../ruler_service.dart';

/// Dialog ya Admin kuona CV KAMILI ya Mwanachama yeyote (Uongozi, Elimu,
/// Kazi, Mafunzo, Nyaraka) - hii ilikuwa haipo kabisa kwa Admin awali,
/// CV ilikuwa inaonekana kwa Mobile self-service tu.
class RulerCvDialog extends StatefulWidget {
  final int rulerId;
  final String rulerName;
  const RulerCvDialog({super.key, required this.rulerId, required this.rulerName});

  @override
  State<RulerCvDialog> createState() => _RulerCvDialogState();
}

class _RulerCvDialogState extends State<RulerCvDialog> {
  final _service = Get.find<RulerService>();
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _cv;
  bool _isDownloadingPdf = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _cv = await _service.getCv(widget.rulerId);
    } catch (e) {
      _error = 'Imeshindikana kupakia CV.';
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _downloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    try {
      final bytes = await _service.getCvPdfBytes(widget.rulerId);
      downloadBytesAsFile(Uint8List.fromList(bytes), 'CV_${widget.rulerName.replaceAll(' ', '_')}.pdf');
    } catch (e) {
      Get.snackbar('Hitilafu', 'Imeshindikana kupakua CV.', snackPosition: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isDownloadingPdf = false);
    }
  }

  List<Map<String, dynamic>> _section(String key) {
    final list = _cv?[key];
    if (list is List) return list.cast<Map<String, dynamic>>();
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SizedBox(
        width: 560,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: _isLoading
              ? const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              : _error != null
                  ? SizedBox(
                      height: 150,
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(_error!, style: const TextStyle(color: AppColors.danger)),
                        const SizedBox(height: 10),
                        ElevatedButton(onPressed: _load, child: const Text('Jaribu tena')),
                      ]),
                    )
                  : ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 640),
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(child: Text('CV - ${widget.rulerName}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900))),
                                IconButton(
                                  tooltip: 'Pakua PDF',
                                  icon: _isDownloadingPdf
                                      ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primaryGreen),
                                  onPressed: _isDownloadingPdf ? null : _downloadPdf,
                                ),
                                IconButton(onPressed: () => Get.back(), icon: const Icon(Icons.close)),
                              ],
                            ),
                            const Divider(),
                            _CvSection(
                              title: 'Uongozi',
                              icon: Icons.emoji_events_outlined,
                              items: _section('positions'),
                              lineBuilder: (p) => 'Nafasi #${p['leadership_id']} - ${p['start_date'] ?? '-'} hadi ${p['end_date'] ?? 'sasa'}',
                            ),
                            _CvSection(
                              title: 'Elimu',
                              icon: Icons.school_outlined,
                              items: _section('educations'),
                              lineBuilder: (e) => '${e['institute'] ?? '-'} - ${e['education_program'] ?? e['education_level'] ?? ''}',
                            ),
                            _CvSection(
                              title: 'Uzoefu wa Kazi',
                              icon: Icons.work_outline,
                              items: _section('employments'),
                              lineBuilder: (e) => '${e['title'] ?? ''} - ${e['employment'] ?? ''} (${e['place'] ?? ''})',
                            ),
                            _CvSection(
                              title: 'Mafunzo',
                              icon: Icons.military_tech_outlined,
                              items: _section('trainings'),
                              lineBuilder: (t) => '${t['training_name'] ?? '-'} (${t['training_type'] ?? ''})',
                            ),
                            _CvSection(
                              title: 'Vyeti na Nyaraka',
                              icon: Icons.description_outlined,
                              items: _section('attachments'),
                              lineBuilder: (a) => a['attachment_name']?.toString() ?? '-',
                            ),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

class _CvSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Map<String, dynamic>> items;
  final String Function(Map<String, dynamic>) lineBuilder;

  const _CvSection({required this.title, required this.icon, required this.items, required this.lineBuilder});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, size: 17, color: AppColors.primaryGreen),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
          ]),
          const SizedBox(height: 8),
          if (items.isEmpty)
            const Text('Hakuna taarifa.', style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary))
          else
            ...items.map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('• ${lineBuilder(e)}', style: const TextStyle(fontSize: 13)),
                )),
        ],
      ),
    );
  }
}
