import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../network/api_client.dart';
import '../theme/app_colors.dart';
import '../../modules/rulers/ruler_service.dart';

/// Avatar ya pamoja inayoonyesha PICHA HALISI ya Mwanachama (ikiwa
/// ameipakia), au herufi za mwanzo za jina lake (initials) kama
/// "fallback" - inatumika KILA MAHALI penye avatar ya Ruler (Mazungumzo,
/// Comments, n.k.) kwa muonekano mmoja thabiti.
class RulerAvatar extends StatefulWidget {
  final int? rulerId;
  final String name;
  final double radius;

  const RulerAvatar({super.key, required this.rulerId, required this.name, this.radius = 20});

  @override
  State<RulerAvatar> createState() => _RulerAvatarState();
}

class _RulerAvatarState extends State<RulerAvatar> {
  List<int>? _photoBytes;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPhoto();
  }

  @override
  void didUpdateWidget(covariant RulerAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rulerId != widget.rulerId) {
      _loaded = false;
      _photoBytes = null;
      _loadPhoto();
    }
  }

  Future<void> _loadPhoto() async {
    if (widget.rulerId == null) {
      if (mounted) setState(() => _loaded = true);
      return;
    }
    try {
      final service = RulerService(Get.find<ApiClient>());
      final bytes = await service.getPhotoBytes(widget.rulerId!);
      if (mounted) setState(() {
        _photoBytes = bytes;
        _loaded = true;
      });
    } catch (_) {
      if (mounted) setState(() => _loaded = true);
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    if (_loaded && _photoBytes != null && _photoBytes!.isNotEmpty) {
      return CircleAvatar(
        radius: widget.radius,
        backgroundColor: AppColors.inputFill,
        backgroundImage: MemoryImage(Uint8List.fromList(_photoBytes!)),
      );
    }
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: AppColors.primaryGreen,
      child: Text(_initials(widget.name), style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: widget.radius * 0.55)),
    );
  }
}
